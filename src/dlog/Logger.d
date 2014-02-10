module dlog.Logger;

import std.stdio;
import std.format;
import std.array;
import std.traits;
import std.conv;
import std.datetime;
import std.algorithm;
import core.time;

import dlog.LogBackend;
import dlog.FunctionStatistic;
import dlog.Message;

enum Level {info, fatal, error, warning, statistic, trace, debugger, test};
string[] levels = [ __traits(allMembers, Level) ];
const enum bool[string] debugs = ["RequestLine" : true ];
Logger log;

class Logger
{
    mixin(logLevelGenerator());       
  	void register(LogBackend lb, string[] levelsFilter=levels)
   	{
   	    foreach(level; levelsFilter)
   	    {
   	        //writeln("Registring ", typeof(lb).stringof, " in level ", level);
   	        writeln("Registring ", lb.toString, " in level ", level);
   	        backends[level] ~= lb;
   	    }
   	}
            
    auto log(S...)(string level, S args)
    {
        write(level, args);
    }
        
    auto enterFunction(string currentFunction)
    {
        callStack ~= currentFunction;
    }
 
    auto leaveFunction()
    {
        callStack.popBack();
    }

    auto savePerfFunction(string currentFunction, TickDuration duration)
    {
        if( !(currentFunction in functionStats))
        {
            functionStats[currentFunction] = new FunctionStatistic(currentFunction);
        }
        functionStats[currentFunction].totalDuration += duration;
        functionStats[currentFunction].timesCalled += 1;
    }

    auto printFunctionStats()
    {
        foreach(functionStat ; getSortedFunctionStats())
        {
            info(functionStat.fullName,
                 ", called ", functionStat.timesCalled," times"
                 ", took ", functionStat.totalTime.nsecs,
                 ", average time per call : ", functionStat.averageTimePerCall.nsecs);
        }
    }

    auto getSortedFunctionStats() 
    {
        auto sortedFunctionStats = functionStats.values;
        sort!((a,b) {return a.fullName < b.fullName;})(sortedFunctionStats);
        return sortedFunctionStats;
    }

    auto getStackTrace()
    {
        string st;
	    foreach(index, context ; callStack)
        {
            st ~= ((index > 0 ? ":" : "") ~ context ~ "()");
        }
        return st;
    }
 
    private:
        
        static string logLevelGenerator()
        {
            string code;
            
            foreach(level ; [EnumMembers!Level])
            {
                code ~= "void " ~ to!string(level) ~ "(S...)(S args){log(\"" ~ to!string(level) ~ "\", args);}";
            }
            
            return code;
        }
        
    	void write(S...)(string type, S args)
	    {
		    auto writer = appender!string();
            foreach(arg; args)
            {
            	formattedWrite(writer, "%s", arg);
            }
            
            if(type in backends)
            {
                auto supportedBackends = backends[type];
	            foreach(backend; supportedBackends)
	            {
	                auto m = new Message(type, writer.data);
                    m.graph = getStackTrace();
	                backend.log(m);
        	    }
        	}
    	}

        // stores the total time of execution for each functions
        FunctionStatistic[string] functionStats;

        string[] callStack;
        LogBackend[][string] backends;
}

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

class FunctionLog
{
    this(string functionName, string functionFullName)
    {
        duration = TickDuration.currSystemTick(); 
        this.functionName = functionName;
        this.functionFullName = functionFullName;
        log.enterFunction(functionName);
    }
    
    auto ended()
    {
        duration =  TickDuration.currSystemTick() - duration;
        log.leaveFunction();
        log.savePerfFunction(functionFullName, duration);
    }

    string functionName;
    string functionFullName;
    TickDuration duration;
}

// RAII Tracer
auto Tracer()
{
    string code;
    version(tracing)
    {
        code ~= 
        q{
            enum __marker{EMPTY}
             
            const auto __context = __traits(identifier, (__traits(parent,__marker)));
            // we are in a class method, extract Class.Method
            static if(__traits(compiles,this))
            {
                const auto __context2 = typeof(this).stringof ~ "." ~ __context;
            }
            static if(__traits(compiles,__context2))
            {
                auto __tracer_ = new FunctionLog (__context2, __context2);
            }
            // we are in a normal function, extract Function name
            else
            {
                auto __tracer_ = new FunctionLog (__context, fullyQualifiedName!(__traits(parent,__marker)));
            }
            scope(exit)
            {
                __tracer_.ended();
            }
        };
    }
    return code;
}

static this()
{
    try
    {
        log = new Logger();
        log.register(new ConsoleLogger);
    }
    catch(Exception e)
    {
        log.error(e.msg);
    }
    
    /*
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
}

