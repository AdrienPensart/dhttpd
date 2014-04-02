module dlog.Message;

import std.datetime;
import core.thread;
import msgpack;

class Message
{
    // tick duration, for message reordering (multithread logging)
    TickDuration tick;
    // Process ID
    int pid;
    // thread UUID emitter
    string tag;
    // simple call stack
    string graph;
    // message substance
    string message;
    // log type (info, trace, etc)
    string type;

    // date of emission (for log store)
	string date;

    @property SysTime sysdate() const
    {
        return SysTime.fromISOString(date);
    }
    
    this()
    {
    }

    this(string type, string tag, string message, string graph)
    {
        this.pid = getpid();
        this.tag = tag;
        this.type = type;
        this.message = message;
        this.graph = graph;
        this.date = Clock.currTime().toISOString();
        this.tick = TickDuration.currSystemTick();
    }
}
