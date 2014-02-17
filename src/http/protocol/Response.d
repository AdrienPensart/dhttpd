module http.protocol.Response;

import std.file;
import std.array;
import std.stdio;
import std.format;
import std.conv;

import http.server.Config;
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
        
        if(content.length)
        {
            formattedWrite(writer, "\r\n%s", content);
        }
        
        return writer.data;
    }
}

class BadRequestResponse : Response
{
    this()
    {
        status = Status.BadRequest;            
        content = readText(Config.getInstallDir() ~ "/public/400.html");
        protocol = http.protocol.Protocol.Protocol.DEFAULT;
        //headers[Header.Connection] = "close";
        headers[Header.ContentType] = "text/html";
        headers[Header.Date] = getDateRFC1123();
        headers[Header.Server] = Config.getServerString();
    }
}

class NotFoundResponse : Response
{
    this()
    {
        status = Status.NotFound;
        content = readText(Config.getInstallDir() ~ "/public/404.html");
        protocol = http.protocol.Protocol.Protocol.DEFAULT;
        //headers[Header.Connection] = "close";
        headers[Header.ContentType] = "text/html";
        headers[Header.Date] = getDateRFC1123();
        headers[Header.Server] = Config.getServerString();
    }
}

class NotAllowedResponse : Response
{
    this()
    {
        status = Status.NotAllowed;         
        content = readText(Config.getInstallDir() ~ "/public/405.html");
        protocol = http.protocol.Protocol.Protocol.DEFAULT;
        //headers[Header.Connection] = "close";
        headers[Header.ContentType] = "text/html";
        headers[Header.Date] = getDateRFC1123();
        headers[Header.Server] = Config.getServerString();
    }
}
