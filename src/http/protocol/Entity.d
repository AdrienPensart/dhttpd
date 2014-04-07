module http.protocol.Entity;

import http.protocol.Date;
import http.poller.FilePoller;
import http.server.Connection;
import dlog.Logger;

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

    this(string a_path)
    {
        m_poller = fileCache.get(a_path, { return new FilePoller(a_path); } );
    }

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
        content = a_content;
    }

    @property char[] content()
    {
        return m_content;
    }

    @property char[] content(char[] a_content)
    {
        m_lastModified = nowRFC1123();
        return m_content = a_content;
    }

    @property char[] content(string a_content)
    {
        m_lastModified = nowRFC1123();
        return m_content = a_content.dup;
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
