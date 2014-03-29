module http.poller.FilePoller;

import deimos.ev;
import loop.EvLoop;
import dlog.Logger;
import core.memory;
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

    this(string a_path, EvLoop a_loop)
    {
    	mixin(Tracer);
    	m_loop = a_loop;
    	m_path = a_path.dup;

    	log.info("Loading and following file ", a_path);
    	m_content = readText!(char[])(m_path);

    	ev_stat_init (&m_stat, &handleFilechange, m_path.ptr, 0.);
   		ev_stat_start (m_loop.loop(), &m_stat);

   		GC.addRoot(cast(void*)&this);
        GC.setAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
    }

    @property auto content()
    {
    	if(reload)
    	{
    		log.info("Reloading file ", m_path);
    		m_content = readText!(char[])(m_path);
    		reload = false;
    	}
    	return m_content;
    }

    void release()
    {
    	mixin(Tracer);
    	ev_stat_stop(m_loop.loop(), &m_stat);
    	GC.removeRoot(cast(void*)&this);
        GC.clrAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
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
