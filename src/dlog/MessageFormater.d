module dlog.MessageFormater;

import std.string : format;
import std.format;
import std.array;
import std.conv;
import std.json;
import std.csv;
import std.xml;
import dlog.Message;

interface MessageFormater
{
    string format(const Message m);
}

class DefaultMessageFormater : MessageFormater
{
    string format(const Message m)
    {
        return .format("%s\n%s\n%s\n%s\n%s\n%s\n", m.tick, m.date, m.threadName, m.graph, m.message, m.type);
    }
}

class LineMessageFormater : MessageFormater
{
    string format(const Message m)
	{
        auto writer = appender!string();
        version(assert)
        {
            formattedWrite(writer, "[%s from %s]", m.type, m.threadName[0..8]);
            formattedWrite(writer, "(%s/%s/%s %s:%s:%s)", m.date.day(), m.date.month(), m.date.year(), m.date.hour(), m.date.minute(), m.date.second());
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

import orange.serialization._;
import orange.serialization.archives._;

class XmlMessageFormater : MessageFormater
{
    string format(const Message m)
    {
        // does not work cause of Serializable toArray in Orange
        static assert(isSerializable!(Message));

        auto archive = new XmlArchive!(char);
        auto serializer = new Serializer(archive);

        serializer.serialize(m);
        return archive.data;
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
