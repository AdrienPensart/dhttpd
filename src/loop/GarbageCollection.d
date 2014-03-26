module loop.GarbageCollection;

import loop.EvLoop;
import core.memory;

class GarbageCollection
{
    this(EvLoop a_loop, double rate=0.3)
    {
        m_loop = a_loop;
        ev_timer_init (&m_gc_timer, &timed_garbage_collection, 0., rate);
        ev_timer_again (m_loop.loop(), &m_gc_timer);

        ev_idle_init (&m_gc_idle, &idle_garbage_collection);
        ev_idle_start (m_loop.loop(), &m_gc_idle);
    }
    
    ~this()
    {
        ev_timer_stop(m_loop.loop(), &m_gc_timer);
        ev_idle_stop(m_loop.loop(), &m_gc_idle);
    }

    private
    {
        EvLoop m_loop;
        ev_timer m_gc_timer;
        ev_idle m_gc_idle;
    }
    
    static private extern(C)
    {
        void idle_garbage_collection(ev_loop_t * loop, ev_idle * w, int revents)
        {
            collect();
        }

        void timed_garbage_collection(ev_loop_t * loop, ev_timer * w, int revents)
        {
            collect();
        }

        void collect()
        {
            GC.collect();
        }
    }
    
    static void disableGC()
    {
        GC.disable();
    }
}
