module http.protocol.StringEntity;

import http.protocol.Entity;
import http.protocol.Date;

import http.server.Connection;

import dlog.Logger;

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
