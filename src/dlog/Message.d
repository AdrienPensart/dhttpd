module dlog.Message;

import std.datetime;

class Message
{
	SysTime date;
    string threadName;
	string graph;
	string message;
    string type;

    this(string type, string threadName, string message)
    {
        this.threadName = threadName;
        this.type = type;
        this.message = message;
        this.date = Clock.currTime();
    }
}

