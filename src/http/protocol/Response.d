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
import http.protocol.Entity;

import http.server.Connection;

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
        Entity m_entity;
        bool m_include;
        static Entity m_defaultEntity;
    }

    static this()
    {
        m_defaultEntity = new StringEntity;
    }

    this(Status a_status, Entity a_entity=m_defaultEntity)
    {
        m_status = a_status;
        m_entity = a_entity;
        updated = true;
        headers[FieldDate] = "";
        protocol = HTTP_1_1;
    }

    @property bool include()
    {
        return m_include;
    }

    @property bool include(bool a_include)
    {
        return m_include = a_include;
    }

    @property Entity entity()
    {
        return m_entity;
    }

    @property Entity entity(Entity a_entity)
    {
        return m_entity = a_entity;
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
        if(reload())
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

            if(m_entity.length)
            {
                headers[ContentLength] = to!string(m_entity.length);
                headers[LastModified] = m_entity.lastModified;
                headers[ETag] = m_entity.etag;
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
    
    bool send(Connection connection)
    {
        mixin(Tracer);
        if(include)
        {
            log.trace("Including entity in response");
            return m_entity.send(header, connection);
        }
        else
        {
            log.trace("DONT include entity in response");
        }
        return connection.writeAll(header);
    }

    bool reload()
    {
        mixin(Tracer);
        return updateToRFC1123(headers[FieldDate]) || updated || m_entity.updated();
    }
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