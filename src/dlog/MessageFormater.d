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
    string format(const Message m);
}

class DefaultMessageFormater : MessageFormater
{
    string format(const Message m)
    {
        return .format("%s\n%s\n%s\n%s\n%s\n%s\n", m.type, m.pid, m.tag, m.tick, m.sysdate, m.graph, m.message);
    }
}

class LineMessageFormater : MessageFormater
{
    string format(const Message m)
	{
        auto writer = appender!string();
        version(assert)
        {
            formattedWrite(writer, "[%s, %s, %s]", m.type, m.pid, m.tag[0..8]);
            formattedWrite(writer, "(%s/%s/%s %s:%s:%s)", m.sysdate.day(), m.sysdate.month(), m.sysdate.year(), m.sysdate.hour(), m.sysdate.minute(), m.sysdate.second());
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
        return writer.data;
    }
}

class BinaryMessageFormater : MessageFormater
{
    string format(const Message m)
    {
        ubyte[] outData = pack(m);
        char * outChar = cast(char*)outData;
        string outString = cast(string)outChar[0..outData.length];
        /*
        import std.stdio;
        writeln(outString);
        */
        return outString;
        /*
        auto dmf = new DefaultMessageFormater;
        return dmf.format(m);
        */
    }
}

/*
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

class JsonMessageFormater : MessageFormater
{
    override string format(const Message)
    {
        return "";
    }
}
*/
