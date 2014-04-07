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
import http.Connection;
import http.poller.FilePoller;

import dlog.Logger;

public import core.sys.posix.sys.uio;

interface Entity
{
    bool send(char[] header, Connection connection);
    size_t length();
    bool updated();
    string lastModified();

    final string etag()
    {
        import std.digest.ripemd;
        return ripemd160Of(lastModified()).toHexString.idup;
    }
}

class FileEntity : Entity
{
    FilePoller * m_poller;

    this(FilePoller * a_poller)
    {
        m_poller = a_poller;
    }

    bool send(char[] header, Connection connection)
    {
        if(m_poller.stream())
        {
            log.trace("Response is too BIG to be sent in oneshot, writing header");
            return connection.writeAll(header) && connection.writeFile(m_poller);
        }
        else
        {
            log.trace("Response is small enough to be sent in oneshot");
            return connection.writeAll(header ~ m_poller.content);
        }
    }

    bool updated()
    {
        return m_poller.reload();
    }

    size_t length()
    {
        return m_poller.length;
    }

    string lastModified()
    {
        return convertToRFC1123(m_poller.lastModified());
    }
}

class StringEntity : Entity
{
    char[] m_content;
    string m_lastModified;

    this()
    {

    }

    this(char[] a_content)
    {
        m_content = a_content;
        m_lastModified = nowRFC1123();
    }

    bool send(char[] a_header, Connection a_connection)
    {
        return a_connection.writeAll(a_header ~ m_content);
    }

    size_t length()
    {
        return m_content.length;
    }

    bool updated()
    {
        return false;
    }

    string lastModified()
    {
        return m_lastModified;
    }
}

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

    this(Status a_status)
    {
        updated = true;
        headers[FieldDate] = "";
        protocol = HTTP_1_1;
        m_entity = m_defaultEntity;
        m_status = a_status;
    }

    this(Status a_status, string a_path)
    {
        this(a_status);
        m_entity = new FileEntity(fileCache.get(a_path, { return new FilePoller(a_path); } ));
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