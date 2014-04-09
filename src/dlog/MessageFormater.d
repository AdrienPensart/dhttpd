module dlog.MessageFormater;

import std.string : format;
import std.format;
import std.array;
import std.conv;
import std.json;
import std.csv;
import std.xml;
import dlog.Message;
import msgpack;

interface MessageFormater
{
    void[] format(const Message m);
}

class DefaultMessageFormater : MessageFormater
{
    void[] format(const Message m)
    {
        return cast(void[]).format("%s\n%s\n%s\n%s\n%s\n%s\n", m.type, m.pid, m.tag, m.tick, m.sysdate, m.graph, m.message);
        //return cast(void[]).format("%s\n%s\n%s\n%s\n%s\n%s\n", m.type, m.pid, m.tag, m.tick, m.date, m.graph, m.message);
    }
}

class LineMessageFormater : MessageFormater
{
    void[] format(const Message m)
	{
        auto writer = appender!string();
        version(assert)
        {
            formattedWrite(writer, "[%s, %s, %s]", m.type, m.pid, m.tag[0..8]);
            formattedWrite(writer, "(%s/%s/%s %.02d:%.02d:%.02d)", m.sysdate.day(), m.sysdate.month(), m.sysdate.year(), m.sysdate.hour(), m.sysdate.minute(), m.sysdate.second());
            //formattedWrite(writer, "(%s)", m.date);
        }
        else
        {
            formattedWrite(writer, "[%s]", m.type);
        }
        
        if(m.graph.length)
        {
            formattedWrite(writer, "{%s}", m.graph);
        }
        formattedWrite(writer, " %s", m.message);
        return cast(void[])writer.data;
    }
}

class BinaryMessageFormater : MessageFormater
{
    void[] format(const Message m)
    {
        return pack(m);
    }
}

/*
class SqlRequestMessageFormater : MessageFormater
{
    override void[] format(const Message m)
    {
        return "";
    }
}

class CsvMessageFormater : MessageFormater
{
    override void[] format(const Message m)
    {
        return "";
    }
}

class JsonMessageFormater : MessageFormater
{
    override void[] format(const Message)
    {
        return "";
    }
}
*/
