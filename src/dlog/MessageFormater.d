module dlog.MessageFormater;

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
        string formattedMessage = "[" ~ to!string(m.type) ~ "]";
        
        version(tracing)
        {
            formattedMessage ~= "(" ~ m.date.toSimpleString() ~ ")";
        }

        if(m.graph.length)
        {
            formattedMessage ~= ("{" ~ m.graph ~ "}");
        }    
        formattedMessage ~= (" " ~ m.message);
        return formattedMessage;
    }
}

