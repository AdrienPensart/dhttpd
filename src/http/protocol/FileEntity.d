module http.protocol.FileEntity;

import http.protocol.Entity;
import http.protocol.Date;

import http.poller.FilePoller;
import http.server.Connection;

import dlog.Logger;

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
        return m_poller.file.size();
    }

    string lastModified()
    {
        return convertToRFC1123(m_poller.lastModified());
    }
}
