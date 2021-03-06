module loop.EvLoop;

import std.string;
import std.uuid;
import std.random;

import dlog.Logger;
import loop.Loop;
import loop.Event;

public import deimos.ev;
public import core.sync.mutex;
public import core.stdc.signal;

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

    void addEvent(Event event)
    {
        m_events ~= event;
    }

    override void run()
    {
        foreach(event ; m_events)
        {
            event.enable();
        }
        ev_run(m_loop, 0);
        foreach(event ; m_events)
        {
            event.disable();
        }
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
        Event[] m_events;
    }

    private extern(C) static
    {
        void endchild (ev_loop_t * a_loop, ev_async * a_stop_watcher, int revents)
        {
            log.trace("Received terminating order : ", a_loop, " cause of async io = ", a_stop_watcher);
            ev_break(a_loop, EVBREAK_ALL);
        }
    }
}
