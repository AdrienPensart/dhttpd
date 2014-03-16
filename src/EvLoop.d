module EvLoop;

import std.variant;
import std.string;
import std.uuid;
import std.random;
import dlog.Logger;

public import deimos.ev;
public import core.sync.mutex;
public import core.stdc.signal;
public import core.memory;

import Loop;

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
        ev_timer_stop(a_loop.loop(), &m_gc_timer);
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
        ev_timer_again (m_loop.loop(), &m_reference_counter_timer);
    }
    
    ~this()
    {
        ev_timer_stop(a_loop.loop(), &m_reference_counter_timer);
    }

    private
    {
        EvLoop m_loop;
        ev_timer m_reference_counter_timer;
    }

    private extern(C) static void log_statistic (ev_loop_t * loop, ev_timer * w, int revents)
    {
        import http.server.Connection;
        Connection.showReferences();
    }
}

class EvLoop : Loop
{
    protected this(ev_loop_t * a_loop)
    {
        assert(a_loop);
        m_loop = a_loop;

        m_gen.seed(unpredictableSeed);
        m_id = randomUUID(m_gen);
    }

    this()
    {
        auto a_loop = ev_loop_new(EVFLAG_AUTO);
        this(a_loop);

        ev_async_init(&m_stop_watcher, &endchild);
        ev_async_start(m_loop, &m_stop_watcher);
    }

    ~this()
    {
        ev_async_stop(m_loop, &m_stop_watcher);
        ev_loop_destroy(m_loop);
    }

    void addChild(EvLoop a_loop)
    {
        m_children[a_loop.m_id] = a_loop;
    }

    override void run()
    {
        ev_run(m_loop, 0);
    }

    auto loop()
    {
        return m_loop;
    }

    private
    {
        ev_loop_t * m_loop;
        ev_async m_stop_watcher;
        Xorshift192 m_gen;
        UUID m_id;
        EvLoop [UUID] m_children;
        Variant[] 
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

class DefaultEvLoop : EvLoop
{
    this()
    {
        version(assert)
        {
            int evMajor = ev_version_major();
            int evMinor = ev_version_minor();
            string evVersion = format("%s.%s", evMajor, evMinor);
            log.info("Libev version : ", evVersion);
        }

        m_default_loop = ev_default_loop(EVFLAG_AUTO);
        assert(m_default_loop);
        
        m_interruption_watcher.data = &this;
        ev_signal_init (&m_interruption_watcher, &interruption, SIGINT);
        ev_signal_start (m_default_loop, &m_interruption_watcher);

        super(m_default_loop);
        ev_async_stop(m_loop, &m_stop_watcher);
    }

    ~this()
    {
        ev_signal_stop(m_default_loop, &m_interruption_watcher);
    }

    private extern(C) static
    {
        void interruption (ev_loop_t * a_default_loop, ev_signal * a_interruption_watcher, int revents)
        {
            log.error("Received SIGINT");
            auto defaultLoop = cast(DefaultEvLoop *)a_interruption_watcher.data;
            foreach(childId, child ; defaultLoop.m_children)
            {
                log.info("Sending async break to child ", childId, ", loop : ", child.m_loop, ", watcher = ", &child.m_stop_watcher);
                ev_async_send(child.m_loop, &child.m_stop_watcher);
            }
            log.info("Breaking default loop : ", a_default_loop);
            ev_break(a_default_loop, EVBREAK_ALL);
        }
    }

    ev_loop_t* m_default_loop;
    ev_signal m_interruption_watcher;
}
