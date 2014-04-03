module http.poller.FilePoller;

import deimos.ev;
import loop.EvLoop;
import dlog.Logger;
import crunch.ManualMemory;
import std.string;
import std.file;
import std.stdio;
import http.handler.Directory;

extern(C) size_t sendfile(int out_fd, int in_fd, size_t * offset, size_t count);

struct FilePoller
{
    ev_stat m_stat;
    char[] m_path;
    char[] m_content;
    bool m_reload;
    EvLoop m_loop;
    File m_file;

    mixin ManualMemory;

    this(string a_path, EvLoop a_loop)
    {
        mixin(Tracer);
        m_loop = a_loop;
        m_path = a_path.dup;
        m_file = File(a_path, "rb");
        m_reload = true;

        ev_stat_init (&m_stat, &handleFilechange, m_path.ptr, 0.);
        ev_stat_start (m_loop.loop(), &m_stat);

        acquireMemory();
    }

    auto reload()
    {
        return m_reload;
    }

    @property auto length()
    {
        return m_file.size();
    }

    @property auto content()
    {
        if(m_reload)
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
        ev_stat_stop(m_loop.loop(), &m_stat);
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
                log.info("File deleted ! ");
            }
        }
    }
}
