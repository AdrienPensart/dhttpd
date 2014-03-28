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
    private string m_response;
    private Status m_status;
    private bool m_keepalive;
    // TODO : Cookies handling
    // string[string] cookies;

    this()
    {
        mixin(Tracer);
        updated = true;
        headers[FieldDate] = "";
        m_status = Status.Invalid;
    }

    @property auto status()
    {
        return m_status;
    }

    @property auto status(Status a_status)
    {
        return m_status = a_status;
    }
    
    @property auto keepalive()
    {
        return m_keepalive;
    }

    @property auto keepalive(bool a_keepalive)
    {
        return m_keepalive = a_keepalive;
    }

    string get()
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
                    log.trace("Added header ", index, " <=> ", value);
                    formattedWrite(writer, "%s: %s\r\n", index, value);
                }
            }
            
            formattedWrite(writer, "\r\n");

            if(content.length)
            {
                formattedWrite(writer, "%s", content);
            }
            m_response = writer.data;
            updated = false;
        }
        return m_response;
    }
}

class BadRequestResponse : Response
{
    this(string file)
    {
        status = Status.BadRequest;            
        content = readText!(char[])(file);
        headers[ContentType] = "text/html";
    }
}

class NotFoundResponse : Response
{
    this(string file)
    {
        status = Status.NotFound;
        content = readText!(char[])(file);
        headers[ContentType] = "text/html";
    }
}

class NotAllowedResponse : Response
{
    this(string file)
    {
        status = Status.NotAllowed;         
        content = readText!(char[])(file);
        headers[ContentType] = "text/html";
    }
}
