module loop.GCEvent;

import dlog.Logger;
import loop.Event;
import loop.EvLoop;
import core.memory;

enum GCMode { automatic, timed, idle };

class GCEvent : Event
{
    private
    {
        EvLoop m_loop;
        ev_timer m_gc_timer;
        ev_idle m_gc_idle;
        GCMode m_gcm;
        double m_rate;
    }

    this(EvLoop a_loop, GCMode a_gcm, double a_rate)
    {
        m_rate = a_rate;
        m_loop = a_loop;
        m_gcm = a_gcm;
    }
    
    override void enable()
    {
        mixin(Tracer);
        final switch(m_gcm)
        {
            case GCMode.automatic:
                log.info("Automatic garbage collection");
                break;
            case GCMode.timed:
                log.info("Enabling timed garbage collection");
                GC.disable();
                ev_timer_init (&m_gc_timer, &timed_garbage_collection, 0., m_rate);
                ev_timer_again (m_loop.loop(), &m_gc_timer);
                break;
            case GCMode.idle:
                log.info("Enabling idle garbage collection");
                GC.disable();
                ev_idle_init (&m_gc_idle, &idle_garbage_collection);
                ev_idle_start (m_loop.loop(), &m_gc_idle);
                break;
        }
    }

    override void disable()
    {
        mixin(Tracer);
        final switch(m_gcm)
        {
            case GCMode.automatic:
                break;
            case GCMode.timed:
                GC.enable();
                ev_timer_stop(m_loop.loop(), &m_gc_timer);
                break;
            case GCMode.idle:
                GC.disable();
                ev_idle_stop(m_loop.loop(), &m_gc_idle);
                break;
        }
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
}
