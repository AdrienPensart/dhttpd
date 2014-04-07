module http.poller.FilePoller;

import std.socket;
import std.string;
import std.file;
import std.stdio;

import deimos.ev;
import loop.EvLoop;
import dlog.Logger;

import crunch.Utils;
import crunch.ManualMemory;

import http.handler.Directory;
import crunch.Caching;

Cache!(string, FilePoller *) fileCache;

enum MAX_BLOCK = 65535u;

struct FileSender
{
    ulong offset;
    ulong sent;
    ulong blockSize;

    bool send(Socket a_socket, FilePoller * a_poller)
    {
        blockSize = (a_poller.length - sent) < MAX_BLOCK ? a_poller.length : MAX_BLOCK;
        sent += a_socket.sendFile(a_poller.fd, &offset, blockSize);
        //log.trace("Sent ", sent, " bytes on ", poller.length, ", offset = ", offset, ", socket = ", socketFd);
        if(sent >= a_poller.length)
        {
            offset = 0;
            sent = 0;
            blockSize = 0;
            return true;
        }
        return false;
    }
}

struct FilePoller
{
    static EvLoop loop;
    ev_stat m_stat;
    uint m_maxBlock;
    char[] m_path;
    char[] m_content;
    bool m_reload = true;
    bool m_stream = false;
    File m_file;

    mixin ManualMemory;

    this(string a_path)
    {
        mixin(Tracer);
        m_path = a_path.dup;
        m_file = File(a_path, "rb");
        log.trace("Creating file poller for file size : ", length);
        if(length > MAX_BLOCK)
        {
            m_stream = true;
            m_reload = false;
        }

        ev_stat_init (&m_stat, &handleFilechange, m_path.ptr, 0.);
        ev_stat_start (loop.loop(), &m_stat);

        acquireMemory();
    }

    @property auto lastModified()
    {
        return timeLastModified(m_path);
    }

    @property auto stream()
    {
        return m_stream;
    }

    @property int fd()
    {
        return m_file.fileno();
    }

    @property auto length()
    {
        return m_file.size();
    }

    bool reload()
    {
        return m_reload;
    }

    @property auto content()
    {
        if(!m_stream && m_reload)
        {
            log.info("(Re)loading file ", m_path);
            m_content = cast(char[])read(m_path);
            m_reload = false;
        }
        return m_content;
    }

    void release()
    {
        mixin(Tracer);
        ev_stat_stop(loop.loop(), &m_stat);
        fileCache.invalidate(m_path.idup);
        releaseMemory();
    }

    private static extern(C) 
    {
        void handleFilechange(ev_loop_t *loop, ev_stat * watcher, int revents)
        {
            mixin(Tracer);
            auto filePoller = cast(FilePoller *)watcher;

            if (watcher.attr.st_nlink)
            {
                // invalidate file cache
                log.info("File to reload : ", filePoller.m_path);
                filePoller.m_reload = true;
            }
            else
            {
                // file deleted
                log.info("File ", filePoller.m_path, " deleted, destroying poller and invalidating cache.");
                //filePoller.release();
            }
        }
    }
}
