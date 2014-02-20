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
        log.enterFunction(functionName);
    }
    
    auto ended()
    {
        duration =  TickDuration.currSystemTick() - duration;
        log.leaveFunction(functionName);
        log.savePerfFunction(functionFullName, duration);
    }

    string functionName;
    string functionFullName;
    TickDuration duration;
}