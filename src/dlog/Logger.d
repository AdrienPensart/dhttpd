module dlog.Logger;

import core.time : TickDuration, Duration, nsecs;

import std.format;
import std.array;
import std.string;
import std.random;
import std.uuid;
import std.conv;

public import dlog.LogBackend;
public import dlog.Tracer;
public import dlog.FunctionLog;
public import dlog.Message;

public import dlog.ConsoleLogger;
public import dlog.FileLogger;
/*
public import dlog.TcpLogger;
public import dlog.UdpLogger;
public import dlog.ZmqLogger;
*/
public import crunch.ReferenceCounter;
import dlog.Message;

ThreadLogger log;

private:

version(assert) {
    // DEBUG
    enum userLevels = 
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
else {
    // RELEASE
    enum userLevels = 
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

static this()
{
    log = new ThreadLogger;
}

unittest
{
    log.register(new ConsoleLogger, "notdefinedlevel");
    log.notdefinedlevel("test for notdefinedlevel");
}

class ThreadLogger
{
    private
    {
        enum internalLevels = ["logging" : true];

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

    mixin(logLevelGenerator(userLevels));
    mixin(logLevelGenerator(internalLevels));

    // user defined log level
    void opDispatch(string logLevel, Arguments...)(Arguments args)
    {
        mixin(genCall(logLevel));
    }

    this()
    {
        m_gen.seed(unpredictableSeed);
        UUID loggerUUID = randomUUID(m_gen);
        m_name = loggerUUID.toString();
        m_creation = TickDuration.currSystemTick();
        register(new ConsoleLogger, internalLevels);
    }

    @property auto name()
    {
        return m_name;
    }

  	auto register(LogBackend lb, bool[string] levelsFilter=userLevels)
   	{
        if(lb.init())
        {
            foreach(level, active; levelsFilter)
            {
                m_backends[level] ~= lb;
            }
            logging("Registered ", typeid(lb), " on ", levelsFilter);
        }
   	}

    auto register(LogBackend lb, string[] levels)
    {
        if(lb.init())
        {
            foreach(level; levels)
            {
                
                m_backends[level] ~= lb;
            }
        }
    }

    auto register(LogBackend lb, string level)
    {
        m_backends[level] ~= lb;
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
            import std.algorithm : sort;
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
        double ratio = cast(double)m_duration.nsecs / cast(double)m_at.nsecs * 100;

        statistic("Virtual total time : ", cast(Duration)m_at);
        statistic("Virtual total time for logging : ", cast(Duration)m_duration);
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

    private
    {
        static auto logLevelGenerator(bool[string] levels)
        {
            string code;
            foreach(level, enabled ; levels)
            {
                // when a log level is disabled, the compiler optimize empty calls
                code ~= "void "~ level ~"(S...)(S args){"~ (enabled ? "write(\""~ level ~"\", args);" : "") ~ "}";
            }
            return code;
        }

        static auto genCall(string level)
        {
            return "write(\""~ level ~"\", args);";
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
}
