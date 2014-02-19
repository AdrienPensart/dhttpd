module dlog.MessageFormater;

import std.format;
import std.array;
import std.conv;
import std.json;
import std.csv;
import std.xml;

import dlog.Message;

abstract class MessageFormater
{
    string format(const Message m);
}

class SqlRequestMessageFormater : MessageFormater
{
    override string format(const Message m)
    {
        return "";
   	}
}

class CsvMessageFormater : MessageFormater
{
    override string format(const Message m)
    {
        return "";
    }
}

class XmlMessageFormater : MessageFormater
{
    override string format(const Message m)
    {
        return "";
   	}
}

class JsonMessageFormater : MessageFormater
{
    override string format(const Message)
	{
        return "";
    }
}

class LineMessageFormater : MessageFormater
{
    override string format(const Message m)
	{
        auto writer = appender!string();
        formattedWrite(writer, "[%s from %s]", m.type, m.threadName[0..8]);
        version(assert)
        {
            formattedWrite(writer, "(%s/%s/%s %s:%s:%s)", m.date.day(), m.date.month(), m.date.year(), m.date.hour(), m.date.minute(), m.date.second());
        }
        
        if(m.graph.length)
        {
            formattedWrite(writer, "{%s}", m.graph);
        }
        formattedWrite(writer, " %s", m.message);
        return writer.data;
    }
}
