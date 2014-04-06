module http.protocol.Response;

import std.datetime;
import std.file;
import std.array;
import std.format;
import std.conv;

import http.protocol.MessageHeader;
import http.protocol.Date;
import http.protocol.Status;
import http.protocol.Protocol;
import http.protocol.Header;
import http.Transaction;
import http.poller.FilePoller;

import dlog.Logger;

public import core.sys.posix.sys.uio;

class Response
{
    mixin MessageHeader;
    private
    {
        char[] m_header;
        Status m_status = Status.Invalid;
        bool m_keepalive = false;
        iovec[2] m_vecs;
        FilePoller * m_poller;
    }

    this(Status a_status)
    {
        m_status = a_status;
        this();
    }

    this(Status a_status, string a_path)
    {
        m_poller = fileCache.get(a_path, { return new FilePoller(a_path); } );
        this(a_status);
    }

    this()
    {
        updated = true;
        headers[FieldDate] = "";
        protocol = HTTP_1_1;
    }

    @property FilePoller * poller()
    {
        return m_poller;
    }

    @property FilePoller * poller(FilePoller * filePoller)
    {
        return m_poller = filePoller;
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

    char[] header()
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
            if(m_poller && m_poller.length)
            {
                headers[ContentLength] = to!string(m_poller.length);
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
    
    /*
    @property iovec[] vecs()
    {
        m_vecs[0].iov_base = cast(void*)header.ptr;
        m_vecs[0].iov_len = m_header.length;

        m_vecs[1].iov_base = cast(void*)content.ptr;
        m_vecs[1].iov_len = content.length;
        return m_vecs;
    }
    */

    size_t headerLength()
    {
        return header.length;
    }

    size_t bodyLength()
    {
        return m_poller ? m_poller.length : 0;
    }

    size_t totalLength()
    {
        return header.length + (m_poller ? m_poller.length : 0);
    }

    char[] get()
    {
        return header ~ (m_poller ? m_poller.content : "");
    }

    bool reload()
    {
        return m_poller && m_poller.reload;
    }

    bool stream()
    {
        return m_poller && m_poller.stream;
    }
}
