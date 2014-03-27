module http.protocol.Response;

import std.datetime;
import std.file;
import std.array;
import std.format;
import std.conv;

import http.protocol.Message;
import http.protocol.Date;
import http.protocol.Status;
import http.protocol.Protocol;
import http.protocol.Header;

import dlog.Logger;

class Response
{
    mixin Message;

    Status status = Status.Invalid;
    // TODO : Cookies handling
    // string[string] cookies;

    this()
    {
        mixin(Tracer);
        updated = true;
        headers[FieldDate] = "";
    }

    ref string get()
    {
        mixin(Tracer);

        assert(status != Status.Invalid, "HTTP Status code invalid");
        if(updateToRFC1123(headers[FieldDate]) || updated)
        {
            if(status == Status.Continue || status == Status.SwitchProtocol || isError(status))
            {
                log.trace("No date field added");
                headers[FieldDate] = "";
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
            formattedWrite(writer, "%s %d %s\r\n", protocol, status, reason);
            if(content.length)
            {
                headers[ContentLength] = to!string(content.length);
            }
            
            foreach(index, value ; headers)
            {
                if(value.length)
                {
                    formattedWrite(writer, "%s: %s\r\n", index, value);
                }
            }
            
            formattedWrite(writer, "\r\n");

            if(content.length)
            {
                formattedWrite(writer, "%s", content);
            }
            raw = writer.data;
            updated = false;
        }
        return raw;
    }
}

class BadRequestResponse : Response
{
    this(string file)
    {
        status = Status.BadRequest;            
        content = readText(file);
        headers[ContentType] = "text/html";
    }
}

class NotFoundResponse : Response
{
    this(string file)
    {
        status = Status.NotFound;
        content = readText(file);
        headers[ContentType] = "text/html";
    }
}

class NotAllowedResponse : Response
{
    this(string file)
    {
        status = Status.NotAllowed;         
        content = readText(file);
        headers[ContentType] = "text/html";
    }
}
