module http.protocol.Response;

import std.datetime;
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

import dlog.Logger;

class Response : Message
{
    Status status;
    string[string] cookies;
    SysTime buildAt;

    this()
    {
        updated = true;
    }

    // TODO : Cookies handling
    override ref string get()
    {
        mixin(Tracer);
        // one field was updated, rebuild response buffer
        if(updated)
        {
            if(status != Status.Continue || status != Status.SwitchProtocol || isError(status))
            {
                headers[FieldDate] = "";
                updateToRFC1123(buildAt, headers[FieldDate]);
                buildAt = Clock.currTime(TimeZone.getTimeZone("Etc/GMT+0"));
            }

            // HTTP 1.0 does not keep connection alive by default
            /*
            if(protocol == HTTP_1_0 && !hasHeader(Header.Connection, "Keep-Alive"))
            {
                headers[Header.Connection] = "close";
            }
            */

            auto writer = appender!string();
            string reason = toReason(status);
            formattedWrite(writer, "%s %d %s\r\n", cast(string)protocol, status, reason);
            if(content.length)
            {
                headers[ContentLength] = to!string(content.length);
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
            raw = writer.data;
            updated = false;
        }
        return super.get();
    }
}

class BadRequestResponse : Response
{
    this(string file)
    {
        status = Status.BadRequest;            
        content = readText(file);
        headers[ContentType] = "text/html";
        headers[FieldDate] = getDateRFC1123();
    }
}

class NotFoundResponse : Response
{
    this(string file)
    {
        status = Status.NotFound;
        content = readText(file);
        headers[ContentType] = "text/html";
        headers[FieldDate] = getDateRFC1123();
    }
}

class NotAllowedResponse : Response
{
    this(string file)
    {
        status = Status.NotAllowed;         
        content = readText(file);
        headers[ContentType] = "text/html";
        headers[FieldDate] = getDateRFC1123();
    }
}
