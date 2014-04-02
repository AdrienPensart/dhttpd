module loop.LogStatisticEvent;

import std.typecons;
import std.typetuple;
import loop.Event;
import loop.EvLoop;
import dlog.Logger;

import http.Transaction;
import http.Connection;

class LogStatisticEvent : Event
{
    this(EvLoop a_loop)
    {
        m_loop = a_loop;
    }
    
    override void enable()
    {
        mixin(Tracer);
        ev_timer_init(&m_reference_counter_timer, &log_statistic, 0, 1);
        ev_timer_again(m_loop.loop(), &m_reference_counter_timer);
    }

    override void disable()
    {
        mixin(Tracer);
        ev_timer_stop(m_loop.loop(), &m_reference_counter_timer);
    }

    private
    {
        EvLoop m_loop;
        ev_timer m_reference_counter_timer;
    }

    private extern(C) static void log_statistic (ev_loop_t * loop, ev_timer * w, int revents)
    {
        alias RefCountedTypes = TypeTuple!(Connection, Transaction);
        foreach(type ; RefCountedTypes)
        {
            if(type.changed())
            {
                log.statistic(typeid(type), " alive ", type.getAlivedNumber());
            }
        }
        ev_timer_again(loop, w);
    }
}
