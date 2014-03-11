module EventLoop;

import std.string;
import std.uuid;
import std.random;
import dlog.Logger;

public import deimos.ev;
public import core.sync.mutex;
public import core.stdc.signal;
public import core.thread;
public import core.memory;

class TimedGarbageCollection
{
    this(ev_loop_t * ev_loop)
    {
        GC.disable();
        ev_timer_init (&m_gc_timer, &callback, 0., 0.300);
        ev_timer_again (ev_loop, &m_gc_timer);
    }
    
    private
    {
        ev_timer m_gc_timer;
    }

    private extern(C) static void callback(ev_loop_t * loop, ev_timer * w, int revents)
    {
        GC.collect();
    }
}

class TimedStatistic
{
    this(ev_loop_t * ev_loop)
    {
        ev_timer_init(&m_reference_counter_timer, &callback, 0, 1);
        ev_timer_again (ev_loop, &m_reference_counter_timer);
    }
    
    private
    {
        ev_timer m_reference_counter_timer;
    }

    private extern(C) static void callback (ev_loop_t * loop, ev_timer * w, int revents)
    {
        import http.server.Connection;
        Connection.showReferences();
    }
}

abstract class Loop
{
    void run();
}

__gshared Mutex globalLoopMutex;
__gshared ev_loop_t* default_loop;
__gshared LibevLoop [UUID] children;
__gshared ev_signal interruption_watcher;

private extern(C)
{
    static void interruption (ev_loop_t * default_loop, ev_signal * interruption_watcher, int revents)
    {
        synchronized(globalLoopMutex)
        {
            log.error("Received SIGINT");
            foreach(childId, child ; children)
            {
                log.info("Sending async break to child ", childId, ", loop : ", child.loop, ", watcher = ", &child.stop_watcher);
                ev_async_send(child.loop, &child.stop_watcher);
            }
            log.info("Breaking parent loop : ", default_loop);
            ev_break(default_loop, EVBREAK_ALL);
        }
    }

    static void endchild (ev_loop_t * loop, ev_async * pstop_watcher, int revents)
    {
        log.info("Received terminating order : ", loop, " cause of async io = ", pstop_watcher);
        ev_break(loop, EVBREAK_ALL);
    }
}

shared static this()
{
    /*
    version(assert)
    {
        int evMajor = ev_version_major();
        int evMinor = ev_version_minor();
        string evVersion = format("%s.%s", evMajor, evMinor);
        log.trace("Libev version : ", evVersion);
    }
    */

    globalLoopMutex = new Mutex;
    default_loop = ev_default_loop(EVFLAG_AUTO);
    assert(default_loop);
    
    ev_signal_init (&interruption_watcher, &interruption, SIGINT);
    ev_signal_start (default_loop, &interruption_watcher);
}

class LibevLoop : Loop
{
    this()
    {
        synchronized(globalLoopMutex)
        {
            m_loop = ev_loop_new(EVFLAG_AUTO);
            assert(m_loop);

            timedStatistic = new TimedStatistic(m_loop);

            ev_async_init(&stop_watcher, &endchild);
            ev_async_start(m_loop, &stop_watcher);

            gen.seed(unpredictableSeed);
            id = randomUUID(gen);
            children[id] = this;
        }
    }

    ~this()
    {
        synchronized(globalLoopMutex)
        {
            ev_async_stop(m_loop, &stop_watcher);
            children.remove(id);
            ev_loop_destroy(m_loop);
        }
    }

    override void run()
    {
        ev_run(m_loop, 0);
    }

    static auto defaultLoop()
    {
        return default_loop;
    }

    static auto runDefaultLoop()
    {
        ev_run(default_loop, 0);
    }
    
    auto loop()
    {
        return m_loop;
    }

    private
    {
        TimedStatistic timedStatistic;
        ev_loop_t * m_loop;
        ev_async stop_watcher;
        Xorshift192 gen;
        UUID id;
    }
}
