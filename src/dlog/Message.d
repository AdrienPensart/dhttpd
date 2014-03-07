module dlog.Message;

import std.datetime;

class Message
{
    // tick duration, for message reordering (multithread logging)
    TickDuration tick;
    // date of emission (for log store)
	SysTime date;
    // thread UUID emitter
    string threadName;
    // simple call stack
	string graph;
    // message substance
	string message;
    // log type (info, trace, etc)
    string type;

    this(string type, string threadName, string message, string graph)
    {
        this.threadName = threadName;
        this.type = type;
        this.message = message;
        this.graph = graph;
        
        this.date = Clock.currTime();
        this.tick = TickDuration.currSystemTick();
    }
}

