module dlog.Message;

import std.datetime;
import orange.serialization._;

class Message : Serializable
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

    // does not work cause of Serializable toArray in Orange
    //mixin NonSerialized!(date);
    // workaround : 
    //enum __nonSerialized = ["date"];

    this(string type, string threadName, string message, string graph)
    {
        this.threadName = threadName;
        this.type = type;
        this.message = message;
        this.graph = graph;
        this.date = Clock.currTime();
        this.tick = TickDuration.currSystemTick();
    }

    override void toData (Serializer serializer, Serializer.Data key) const
    {
        serializer.serialize(tick, tick.stringof);
        serializer.serialize(threadName, threadName.stringof);
        serializer.serialize(graph, graph.stringof);
        serializer.serialize(message, message.stringof);
        serializer.serialize(type, type.stringof);

        serializer.serialize(date.toISOString(), date.stringof);
    }

    override void fromData (Serializer serializer, Serializer.Data key)
    {
        tick = serializer.deserialize!(typeof(tick))(tick.stringof);
        threadName = serializer.deserialize!(typeof(threadName))(threadName.stringof);
        graph = serializer.deserialize!(typeof(graph))(graph.stringof);
        message = serializer.deserialize!(typeof(message))(message.stringof);
        type = serializer.deserialize!(typeof(type))(type.stringof);

        date = date.fromISOString(serializer.deserialize!(string)(date.stringof));
    }
}
