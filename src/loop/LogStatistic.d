module loop.LogStatistic;

import loop.Event;
import loop.EvLoop;
import dlog.Logger;
import http.Connection;

class LogStatistic : Event
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
        Connection.showReferences();
        ev_timer_again(loop, w);
    }
}
