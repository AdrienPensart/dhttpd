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

enum MAX_SIZE_PER_CACHE_ENTRY = 65535u;

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
        log.trace("Creating file poller for file size : ", m_file.size());
        if(m_file.size() > MAX_SIZE_PER_CACHE_ENTRY)
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

    @property File file()
    {
        return m_file;
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
