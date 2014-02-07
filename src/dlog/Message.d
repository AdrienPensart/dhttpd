module dlog.Message;

import std.datetime;

class Message
{
	SysTime date;
	string graph;
	string message;
    string type;

    this(string type, string message)
    {
        this.type = type;
        this.message = message;
        this.date = Clock.currTime();
    }
}

