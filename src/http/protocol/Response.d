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

public import core.sys.posix.sys.uio;

class Response
{
    mixin Message;
    private char[] m_header;
    private Status m_status = Status.Invalid;
    private bool m_keepalive = false;
    private iovec[2] m_vecs;

    // TODO : Cookies handling
    // string[string] cookies;

    this()
    {
        mixin(Tracer);
        updated = true;
        headers[FieldDate] = "";
        protocol = HTTP_1_1;
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

    @property char[] header()
    in
    {
        assert(status != Status.Invalid, "HTTP Status code invalid");
    }
    body
    {
        mixin(Tracer);
        if(updateToRFC1123(headers[FieldDate]) || updated)
        {
            if(status == Status.Continue || status == Status.SwitchProtocol || isError(status))
            {
                log.trace("No date field added");
                headers[FieldDate] = "";
            }

            auto writer = appender!(char[])();
            //m_header.length = 0;
            //auto writer = RefAppender!(char[])(&m_header);

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
                    //log.trace("Added header ", index, " <=> ", value);
                    formattedWrite(writer, "%s: %s\r\n", index, value);
                }
            }
            formattedWrite(writer, "\r\n");
            m_header = writer.data;
            updated = false;
        }
        return m_header;
    }
    
    char[] get()
    {
        return header ~ content;
    }

    @property iovec[] vecs()
    {
        m_vecs[0].iov_base = cast(void*)header.ptr;
        m_vecs[0].iov_len = m_header.length;

        m_vecs[1].iov_base = cast(void*)content.ptr;
        m_vecs[1].iov_len = content.length;
        return m_vecs;
    }

    @property auto length()
    {
        return m_header.length + m_content.length;
    }
}

class EntityTooLargeResponse : Response
{
    this()
    {
        status = Status.RequestEntityTooLarge;
    }
}

class PreConditionFailedResponse : Response
{
    this()
    {
        status = Status.PrecondFailed;
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
