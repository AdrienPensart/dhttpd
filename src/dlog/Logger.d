module dlog.Logger;

import std.stdio;
import std.format;
import std.array;
import std.string;
import std.random;
import std.uuid;
import std.conv;
import std.algorithm;
import std.traits : EnumMembers;
import core.thread;

public import dlog.LogBackend;
public import dlog.Tracer;
public import dlog.FunctionLog;
import dlog.ThreadLog;
import dlog.FunctionStatistic;
import dlog.Message;

enum DISABLE = 100;
version(assert)
{
    // DEBUG
    enum Level
    {
        info = 1,
        fatal = 2,
        error = 3, 
        warning = 4, 
        statistic = 5,
        trace = 103, 
        debugger = 104, 
        test = 105
    }
}
else
{
    // RELEASE
    enum Level
    {
        info = 1,
        fatal = 2,
        error = 3, 
        warning = 4,
        statistic = 5,
        trace = 103, 
        debugger = 104, 
        test = 105
    }
}

immutable string[] levels = [ __traits(allMembers, Level) ];

__gshared Logger log;

shared static this()
{
    log = new Logger();
}

shared static ~this()
{
    log.printStats();
}

class Logger
{
    mixin(logLevelGenerator());

    this()
    {
        gen.seed(unpredictableSeed);
    }

  	auto register(LogBackend lb, immutable string[] levelsFilter=levels)
   	{
        synchronized
        {
            foreach(level; levelsFilter)
            {
                backends[level] ~= lb;
            }
            if(levelsFilter.length)
            {
                writefln("Existing levels : %-(%s, %)", levelsFilter);
            }
        }
   	}

    auto log(S...)(string level, S args)
    {
        synchronized
        {
            TickDuration duration = TickDuration.currSystemTick();
            write(level, args);
            duration =  TickDuration.currSystemTick() - duration;
            writeDuration += duration;
        }
    }
    
    auto enterFunction(string currentFunction)
    {
        synchronized
        {
            auto threadName = Thread.getThis().name();

            // thread uuid creation
            if(!threadName.length)
            {
                UUID currentThreadUUID = randomUUID(gen);
                threadName = currentThreadUUID.toString();
                Thread.getThis().name(threadName);
                threadLogs[threadName] = ThreadLog(threadName);
            }
            threadLogs[threadName].push(currentFunction);
        }
    }
 
    auto leaveFunction(string currentFunction)
    {
        synchronized
        {
            threadLogs[Thread.getThis().name()].pop();
        }
    }

    auto savePerfFunction(string functionFullName, TickDuration duration)
    {
        synchronized
        {
            if(!(functionFullName in functionStats))
            {
                functionStats[functionFullName] = FunctionStatistic(functionFullName);
            }
            functionStats[functionFullName].totalDuration += duration;
            functionStats[functionFullName].timesCalled += 1;
        }
    }

    auto printStats()
    {
        synchronized
        {
            foreach(functionStat ; getSortedFunctionStats())
            {
                statistic(functionStat.fullName,
                     ", called : ", functionStat.timesCalled," time(s)"
                     ", took : ", functionStat.totalTime.nsecs,
                     ", average : ", functionStat.averageTimePerCall.nsecs);
            }

            TickDuration total;
            foreach(threadLog ; threadLogs)
            {
                total += threadLog.getDuration();
            }

            statistic("Threads created : ", threadLogs.length);
            statistic("Virtual total time (all threads) : ", toTime(total).nsecs);
            statistic("Virtal total time of log writing (all threads) : ", toTime(writeDuration).nsecs);
            double ratio = cast(double)writeDuration.nsecs / cast(double)total.nsecs * 100;
            statistic("Ratio of log writing (all threads) : ", ratio, "%");
        }
    }

    auto getSortedFunctionStats() 
    {
        synchronized
        {
            auto sortedFunctionStats = functionStats.values;
            sort!((a,b) {return a.totalDuration > b.totalDuration;})(sortedFunctionStats);
            return sortedFunctionStats;
        }
    }

    private:
        
        static string logLevelGenerator()
        {
            string code;
            foreach(i, level ; EnumMembers!Level)
            {
                pragma(msg, to!string(level), " : ", level < DISABLE ? "enabled" : "disabled");
                // when a log level is disabled, the compiler optimize empty calls
                code ~= "void "~to!string(level)~"(S...)(S args){"~ (level < DISABLE ? "log(\""~to!string(level)~"\", args);" : "") ~ "}";
            }
            return code;
        }
        
    	void write(S...)(string type, S args)
	    {            
            if(type in backends)
            {
                auto writer = appender!string();
                foreach(arg; args)
                {
                    formattedWrite(writer, "%s", arg);
                }

                auto supportedBackends = backends[type];
	            foreach(backend; supportedBackends)
	            {
                    auto threadName = Thread.getThis().name();
                    auto m = new Message(type, threadName, writer.data);

                    m.graph = threadLogs[threadName].getStackTrace();
	                backend.log(m);
        	    }
        	}
    	}

        Xorshift192 gen;

        // stores the total time of execution for each functions
        FunctionStatistic[string] functionStats;

        // one call stack per thread
        ThreadLog[string] threadLogs;

        LogBackend[][string] backends;

        // total time of printing
        TickDuration writeDuration;
}

/*
    // unit testing
    auto smtp = SMTP("smtps://smtp.gmail.com");
    smtp.setAuthentication("crunchengine@gmail.com", "fight1485ij");
    smtp.mailTo = ["adrien.pensart@corp.ovh.com"];
    smtp.mailFrom = "crunchengine@gmail.com";
    lout.register(new SmtpLogger(smtp, 3));
    */
    
    //log.register(new ConsoleLogger(ConsoleLogger.Type.OUT));
    //log.register(new ConsoleLogger(ConsoleLogger.Type.ERR));
    //log.register(new UdpLogger("127.0.0.1", 9000));
    //log.register(new TcpLogger("127.0.0.1", 9000));
    //log.info("an info occured ? lol.");
    /*
    log.log("exception", "an exception occured");
    log.error("an error occured");
    log.warning("a warning occured");
    log.fatal("oups");
    */

/*
const enum bool[string] debugs = ["RequestLine" : true ];
template ProxyDebugger ()
{
    auto DebugLog(S...)(S args)
    {
        const char[] identifier = __traits(identifier, typeof(this));
        static if(debugs[identifier])
        {
            log.write(args);
        }
    }
}
*/