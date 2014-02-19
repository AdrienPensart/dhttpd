module http.protocol.Response;

import std.file;
import std.array;
import std.stdio;
import std.format;
import std.conv;

import http.protocol.Message;
import http.protocol.Date;
import http.protocol.Status;
import http.protocol.Protocol;
import http.protocol.Header;

class Response : Message
{
    Status status;
    string[string] cookies;
    
    string get()
    {
        if(status != Status.Continue || status != Status.SwitchProtocol || isError(status))
        {
            headers[Header.Date] = getDateRFC1123();
        }

        // HTTP 1.0 does not keep alive connection
        if(getProtocol() == Protocol.HTTP_1_0)
        {
            headers[Header.Connection] = "close";
        }

        auto writer = appender!string();

        string reason = toReason(status);
        formattedWrite(writer, "%s %d %s\r\n", cast(string)protocol, status, reason);
        if(content.length)
        {
            headers[Header.ContentLength] = to!string(content.length);
        }
        
        foreach(index, value ; headers)
        {
            formattedWrite(writer, "%s: %s\r\n", index, value);
        }
        
        formattedWrite(writer, "\r\n");

        if(content.length)
        {
            formattedWrite(writer, "%s", content);
        }
        
        return writer.data;
    }
}

class BadRequestResponse : Response
{
    this(string file)
    {
        status = Status.BadRequest;            
        content = readText(file);
        protocol = http.protocol.Protocol.Protocol.DEFAULT;
        //headers[Header.Connection] = "close";
        headers[Header.ContentType] = "text/html";
        headers[Header.Date] = getDateRFC1123();
    }
}

class NotFoundResponse : Response
{
    this(string file)
    {
        status = Status.NotFound;
        content = readText(file);
        protocol = http.protocol.Protocol.Protocol.DEFAULT;
        //headers[Header.Connection] = "close";
        headers[Header.ContentType] = "text/html";
        headers[Header.Date] = getDateRFC1123();
    }
}

class NotAllowedResponse : Response
{
    this(string file)
    {
        status = Status.NotAllowed;         
        content = readText(file);
        protocol = http.protocol.Protocol.Protocol.DEFAULT;
        //headers[Header.Connection] = "close";
        headers[Header.ContentType] = "text/html";
        headers[Header.Date] = getDateRFC1123();
    }
}
