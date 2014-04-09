module dlog.ConsoleLogger;

import dlog.FileLogger;
import dlog.Message;
import dlog.MessageFormater;
import std.stdio;

class ConsoleLogger : FileLogger
{
    enum Type { OUT, ERR, DEFAULT = OUT};

    this()
    {
        this(Type.DEFAULT, new LineMessageFormater);
    }

    this(MessageFormater formater = new LineMessageFormater, Type type = Type.DEFAULT)
    {
        super(type == Type.OUT ? stdout : stderr, formater);
    }

  	this(Type type = Type.DEFAULT, MessageFormater formater = new LineMessageFormater)
  	{
   	    super(type == Type.OUT ? stdout : stderr, formater);
    }
}
