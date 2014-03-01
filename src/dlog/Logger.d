module dlog.Logger;

import core.thread : TickDuration, Thread, nsecs;
import std.algorithm : sort;
import std.format;
import std.array;
import std.string;
import std.random;
import std.uuid;
import std.conv;

public import dlog.LogBackend;
public import dlog.Tracer;
public import dlog.FunctionLog;
public import dlog.AliveReference;

import dlog.ThreadLog;
import dlog.FunctionStatistic;
import dlog.Message;
/*
// WTF ?
const enum bool[string] classdebugs = 
[
    "Connection" : true,
    "Server" : false,
    "Request" : true,
    "Response" : true,
    "Directory" : true,
    "VirtualHost" : true,
    "Route" : true
];

// WTF ??? again.
const enum bool[string] functiondebugs = 
[
    "handleRequest" : false
];
*/
version(assert)
{
    // DEBUG
    const enum bool[string] levels = 
        [
            "info" : true, 
            "fatal" : true,
            "error" : true,
            "warning" : true,
            "statistic" : true,
            "trace" : true,
            "test" : false
        ];
}
else
{
    // RELEASE
    const enum bool[string] levels = 
        [
            "info" : true, 
            "fatal" : true,
            "error" : true,
            "warning" : true,
            "statistic" : false,
            "trace" : false,
            "test" : false
        ];
}

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

    private string getThreadName()
    {
        return Thread.getThis().name();
    }

    private ref ThreadLog getThreadLog()
    {
        auto threadName = getThreadName();
        // thread uuid creation
        if(!threadName.length)
        {
            UUID currentThreadUUID = randomUUID(gen);
            threadName = currentThreadUUID.toString();
            Thread.getThis().name(threadName);
            threadLogs[threadName] = ThreadLog(threadName);
        }
        return threadLogs[threadName];
    }

    bool enabled()
    {
        return getThreadLog().enabled();
    }

    void enable()
    {
        getThreadLog().enable();
    }

    void disable()
    {
        getThreadLog().disable();
    }

  	auto register(LogBackend lb, typeof(levels) levelsFilter=levels)
   	{
        synchronized
        {
            foreach(level, active; levelsFilter)
            {
                backends[level] ~= lb;
            }
            version(assert)
            {
                import std.stdio : writeln;
                writeln("Existing levels : ", levelsFilter);
            }
        }
   	}

    auto log(S...)(string level, S args)
    {
        synchronized
        {
            if(enabled())
            {
                TickDuration duration = TickDuration.currSystemTick();
                write(level, args);
                duration =  TickDuration.currSystemTick() - duration;
                writeDuration += duration;
            }
        }
    }

    auto enter(FunctionLog currentFunction)
    {
        synchronized
        {
            getThreadLog().push(currentFunction);
        }
    }

    auto leave(FunctionLog currentFunction)
    {
        synchronized
        {
            getThreadLog().pop();
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
                total += threadLog.duration;
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
            foreach(level, active ; levels)
            {
                // when a log level is disabled, the compiler optimize empty calls
                code ~= "void "~ level ~"(S...)(S args){"~ (active ? "log(\""~ level ~"\", args);" : "") ~ "}";
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
                    auto threadLog = getThreadLog();
                    auto message = new Message(type, threadLog.name, writer.data, threadLog.stack());
	                backend.log(message);
        	    }
        	}
    	}

        // UUID Random generator
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
