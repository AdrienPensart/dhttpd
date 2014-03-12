module dlog.Logger;

import core.thread : TickDuration, Thread, nsecs;
import core.sync.mutex;

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
public import dlog.ReferenceCounter;
import dlog.Message;


// WTF this type is LoL
// TODO : correct this declaration type
const enum bool[string] internalLevels = ["logging" : true];

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
            "test" : false,
            "dbg" : false,
        ];
}
else
{
    // RELEASE
    enum bool[string] levels = 
        [
            "info" : true, 
            "fatal" : true,
            "error" : true,
            "warning" : true,
            "statistic" : true,
            "trace" : false,
            "test" : false,
            "dbg" : false,
        ];
}

/*
__gshared Logger log;
__gshared Mutex globalLogMutex;

shared static this()
{
    tracerMutex = new Mutex;
    globalLogMutex = new Mutex;
    log = new Logger();
}

shared static ~this()
{
    log.printStats();
}
__gshared Mutex tracerMutex;

*/

ThreadLogger log;

static this()
{
    log = new ThreadLogger;
    log.register(new ConsoleLogger, internalLevels);
}

// issue 5105, synchronized class can't declare template functions
/*synchronized */
class ThreadLogger
{
    private
    {
        // UUID Random generator
        Xorshift192 m_gen;

        // log name
        string m_name;

        // call stack trace
        FunctionLog[] m_callstack;
        
        // output backends : console, file, network, etc
        LogBackend[][string] m_backends;

        // logger creation, for computing logging timings
        TickDuration m_creation;

        // time taken for logging
        TickDuration m_duration;
    }

    mixin(logLevelGenerator());

    @property auto name()
    {
        return m_name;
    }

  	auto register(LogBackend lb, typeof(levels) levelsFilter=levels)
   	{
        foreach(level, active; levelsFilter)
        {
            m_backends[level] ~= lb;
        }
        /*
        version(assert)
        {
            info("Registering ", typeid(lb), " with log levels : ", levelsFilter);
        }
        */
   	}

    auto enter(FunctionLog currentFunction)
    {
        m_callstack ~= currentFunction;
    }

    auto leave(FunctionLog currentFunction)
    {
        if(m_callstack.length)
        {
            m_callstack.popBack();
        }
    }

    auto stats()
    {
        auto getSortedFunctionStats()
        {
            auto sortedFunctionStats = FunctionLog.m_stats.values;
            sort!((a,b) {return a.totalDuration > b.totalDuration;})(sortedFunctionStats);
            return sortedFunctionStats;
        }

        foreach(stat ; getSortedFunctionStats())
        {
            statistic(stat.fullname,
                 ", called : ", stat.timesCalled," time(s)"
                 ", took : ", stat.totalTime.nsecs,
                 ", average : ", stat.averageTime.nsecs);
        }

        TickDuration m_at = TickDuration.currSystemTick() - m_creation;

        statistic("Virtual total time : ", toTime(m_at).nsecs);
        statistic("Virtual total time for logging : ", toTime(m_duration).nsecs);
        double ratio = cast(double)m_duration.nsecs / cast(double)m_at.nsecs * 100;
        statistic("Time wasted : ", ratio, "%");
    }

    void opCall(string level, Message message)
    {
        auto supportedBackends = m_backends[level];
        foreach(backend; supportedBackends)
        {
            backend.log(message);
        }
    }

    private:

        this()
        {
            m_gen.seed(unpredictableSeed);
            UUID currentThreadUUID = randomUUID(m_gen);
            m_name = currentThreadUUID.toString();
            m_creation = TickDuration.currSystemTick();
        }

        static auto logLevelGenerator()
        {
            string code;
            foreach(level, active ; levels)
            {
                // when a log level is disabled, the compiler optimize empty calls
                code ~= "void "~ level ~"(S...)(S args){"~ (active ? "write(\""~ level ~"\", args);" : "") ~ "}";
            }
            foreach(level, active ; internalLevels)
            {
                code ~= "void "~ level ~"(S...)(S args){"~ (active ? "write(\""~ level ~"\", args);" : "") ~ "}";
            }
            return code;
        }

        auto write(S...)(string level, S args)
        {
            if(level in m_backends)
            {
                TickDuration duration = TickDuration.currSystemTick();

                auto writer = appender!string();
                foreach(arg; args)
                {
                    formattedWrite(writer, "%s", arg);
                }

                auto message = new Message(level, m_name, writer.data, stack());                    
                opCall(level, message);

                duration =  TickDuration.currSystemTick() - duration;
                m_duration += duration;
            }
        }

        string stack()
        {
            string s;
            foreach(functionLog ; m_callstack)
            {
                s ~= functionLog.name;
                s ~= ":";
            }
            return s.chop();
        }
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
