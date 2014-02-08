module http.protocol.Response;

import std.array;
import std.stdio;
import std.format;
import std.conv;

import http.protocol.Status;
import http.protocol.Version;

class Response
{
    Status status;
    Version protocolVersion;
    string reason;
    string[string] headers;
    string[string] cookies;
    string message;

    this()
    {
    }
    
    string get()
    {
        auto writer = appender!string();
        formattedWrite(writer, "%s %s %s\r\n", cast(string)protocolVersion, cast(string)status, (status));
        
        if(message.length)
        {
            headers["Content-Length"] = to!string(message.length);
        }
        
        foreach(index, value ; headers)
        {
            formattedWrite(writer, "%s: %s\r\n", index, value);
        }
        
        if(message.length)
        {
            formattedWrite(writer, "\r\n%s", message);
        }
        
        return writer.data;
    }
}

