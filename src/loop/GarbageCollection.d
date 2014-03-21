module loop.GarbageCollection;

import loop.EvLoop;
import core.memory;

class GarbageCollection
{
    this(EvLoop a_loop)
    {
        m_loop = a_loop;
        GC.disable();
        ev_timer_init (&m_gc_timer, &garbace_collection, 0., 0.300);
        ev_timer_again (m_loop.loop(), &m_gc_timer);
    }
    
    ~this()
    {
        ev_timer_stop(m_loop.loop(), &m_gc_timer);
    }

    private
    {
        EvLoop m_loop;
        ev_timer m_gc_timer;
    }

    private extern(C) static void garbace_collection(ev_loop_t * loop, ev_timer * w, int revents)
    {
        GC.collect();
    }
}
