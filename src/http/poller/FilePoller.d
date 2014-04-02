module http.poller.FilePoller;

import deimos.ev;
import loop.EvLoop;
import dlog.Logger;
import crunch.ManualMemory;
import std.string;
import std.file;
import http.handler.Directory;

struct FilePoller
{
    ev_stat m_stat;
    char[] m_path;
    char[] m_content;
    bool reload = false;
    EvLoop m_loop;

    mixin ManualMemory;

    this(string a_path, EvLoop a_loop)
    {
        mixin(Tracer);
        m_loop = a_loop;
        m_path = a_path.dup;

        log.info("Loading and following file ", a_path);
        reload = true;

        ev_stat_init (&m_stat, &handleFilechange, m_path.ptr, 0.);
        ev_stat_start (m_loop.loop(), &m_stat);

        acquireMemory();
    }

    @property auto content()
    {
        if(reload)
        {
            log.info("(Re)loading file ", m_path);
            m_content = cast(char[])read(m_path);
            reload = false;
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
                filePoller.reload = true;
            }
            else
            {
                // file deleted
                log.info("File deleted ! ");
            }
        }
    }
}
