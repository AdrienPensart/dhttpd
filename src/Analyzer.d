public import std.stdio : writeln;
public import core.time : TickDuration;
public import std.traits;
import dlog.Logger;
import Http;

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

auto Tracer()
{
    string code;
    version(tracing)
    {
        code ~= 
        q{
            enum __marker{EMPTY}
             
            const auto __context = __traits(identifier, (__traits(parent,__marker)));
            // in a method
            static if(__traits(compiles,this))
            {
                const auto __context2 = typeof(this).stringof ~ "." ~ __context;
            }
            static if(__traits(compiles,__context2))
            {
                auto __tracer_ = new FunctionLog (__context2, __context2);
            }
            // in a function
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

