module EvLoop;

import std.variant;
import std.string;
import std.uuid;
import std.random;
import dlog.Logger;

public import deimos.ev;
public import core.sync.mutex;
public import core.stdc.signal;

import http.server.Connection;
import Loop;

class GarbageCollection
{
    import core.memory;

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

class LogStatistic
{
    this(EvLoop a_loop)
    {
        m_loop = a_loop;
        ev_timer_init(&m_reference_counter_timer, &log_statistic, 0, 1);
        ev_timer_again(m_loop.loop(), &m_reference_counter_timer);
    }
    
    ~this()
    {
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

class InterruptionEvent
{
    this(EvLoop evloop)
    {
        parent = evloop;
        ev_signal_init (&interruptionWatcher, &interruption, SIGINT);
        ev_signal_start (parent.loop, &interruptionWatcher);
        interruptionWatcher.data = &children;
    }

    ~this()
    {
        //ev_signal_stop(parent.loop, &interruptionWatcher);
    }

    void addChild(EvLoop evLoop)
    {
        children ~= evLoop;
    }

    private
    {
        EvLoop parent;
        EvLoop [] children;
        ev_signal interruptionWatcher;
    }

    private extern(C) static void interruption (ev_loop_t * a_default_loop, ev_signal * a_interruption_watcher, int revents)
    {
        mixin(Tracer);
        log.error("Received SIGINT");
        auto children = cast(EvLoop [] *)a_interruption_watcher.data;
        foreach(child ; *children)
        {
            log.info("Sending async break to child ", child.id, ", loop : ", child.loop, ", watcher = ", child.stopWatcher);
            ev_async_send(child.loop, child.stopWatcher);
        }
        log.info("Breaking default loop : ", a_default_loop);
        ev_break(a_default_loop, EVBREAK_ALL);
    }
}

class EvLoop : Loop
{
    this()
    {
        auto a_loop = ev_loop_new(EVFLAG_AUTO);
        this(a_loop);
    }

    this(ev_loop_t * a_loop)
    {
        assert(a_loop);
        m_loop = a_loop;

        m_gen.seed(unpredictableSeed);
        m_id = randomUUID(m_gen);

        ev_async_init(&m_stop_watcher, &endchild);
        ev_async_start(m_loop, &m_stop_watcher);
    }

    ~this()
    {
        ev_async_stop(m_loop, &m_stop_watcher);
        ev_loop_destroy(m_loop);
    }

    void addEvent(T)(T event)
    {
        Variant vevent = event;
        m_events ~= vevent;
    }

    override void run()
    {
        ev_run(m_loop, 0);
    }

    ev_loop_t * loop()
    {
        return m_loop;
    }

    UUID id()
    {
        return m_id;
    }

    ev_async * stopWatcher()
    {
        return &m_stop_watcher;
    }

    private
    {
        ev_loop_t * m_loop;
        ev_async m_stop_watcher;
        Xorshift192 m_gen;
        UUID m_id;
        Variant[] m_events;
    }

    private extern(C) static
    {
        void endchild (ev_loop_t * a_loop, ev_async * a_stop_watcher, int revents)
        {
            log.info("Received terminating order : ", a_loop, " cause of async io = ", a_stop_watcher);
            ev_break(a_loop, EVBREAK_ALL);
        }
    }
}
