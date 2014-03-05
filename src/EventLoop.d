module EventLoop;

import std.string;
import dlog.Logger;

import czmq;
import zsys;
import libev.ev;
import core.stdc.signal;
import core.memory;

class BlockInterruption
{
    this(ev_loop_t * ev_loop)
    {
        ev_signal_init (&m_signal_watcher, &callback, SIGINT);
        ev_signal_start (ev_loop, &m_signal_watcher);
    }
    
    auto getIO()
    {
        return m_signal_watcher;
    }

    private
    {
        ev_signal m_signal_watcher;
    }

    private extern(C) static void callback (ev_loop_t * loop, ev_signal * w, int revents)
    {
        ev_break(loop, EVBREAK_ALL);
    }
}

class TimedGarbageCollection
{
    this(ev_loop_t * ev_loop)
    {
        GC.disable();
        ev_timer_init (&m_gc_timer, &callback, 0., 0.300);
        ev_timer_again (ev_loop, &m_gc_timer);
    }

    auto getIO()
    {
        return m_gc_timer;
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

    auto getIO()
    {
        return m_reference_counter_timer;
    }

    private
    {
        ev_timer m_reference_counter_timer;
    }

    private extern(C) static void callback (ev_loop_t * loop, ev_timer * w, int revents)
    {
        import http.server.Connection;
        Connection.showReferences();

        /*
        import http.protocol.Response;
        import http.protocol.Request;
        import http.server.Route;
        import http.server.VirtualHost;
        import http.server.Server;
        */
        /*
        Server.showReferences();
        
        Response.showReferences();
        Request.showReferences();
        Route.showReferences();
        VirtualHost.showReferences();
        VirtualHostConfig.showReferences();
        */
    }
}

abstract class Loop
{
    void run();
}

class ZmqLoop : Loop
{
    this()
    {
        /*
        zsys_handler_reset ();
        zsys_handler_set (null);
        */
        int zmqMajor, zmqMinor, zmqPatch;
        zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
        string zmqVersion = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
        log.info("ZMQ version : ", zmqVersion);

        zctx = zctx_new();
        assert(zctx);
        
        //zctx_set_linger (context, 10);
        zloop = zloop_new();
        assert(zloop);
    }

    ~this()
    {
        zctx_destroy(&zctx);
    }

    auto context()
    {
        return zctx;
    }

    override void run()
    {
        
    }

    zctx_t * zctx;
    zloop_t * zloop;
}

class LibevLoop : Loop
{
    this()
    {
        ev_loop = ev_default_loop(EVFLAG_AUTO);
        assert(ev_loop);
    }

    override void run()
    {
        int evMajor = ev_version_major();
        int evMinor = ev_version_minor();
        string evVersion = format("%s.%s", evMajor, evMinor);
        log.info("Libev version : ", evVersion);

        ev_run(loop, 0);
    }

    auto loop()
    {
        return ev_loop;
    }

    private
    {
        ev_loop_t * ev_loop;
    }
}
