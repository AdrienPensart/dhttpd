module dlog.FunctionLog;

import dlog.Logger;
import std.datetime;

struct FunctionLog
{
    this(string functionName, string functionFullName)
    {
        this.duration = TickDuration.currSystemTick();
        this.functionName = functionName;
        this.functionFullName = functionFullName;
        log.enter(functionName);
    }
    
    auto ended()
    {
        duration =  TickDuration.currSystemTick() - duration;
        log.leave(functionName);
        log.savePerfFunction(functionFullName, duration);
    }

    string functionName;
    string functionFullName;
    TickDuration duration;
}