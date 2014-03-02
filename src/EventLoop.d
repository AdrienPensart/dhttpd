module EventLoop;

import std.string;
import dlog.Logger;
import czmq;
import zsys;
import libev.ev;
import core.stdc.signal;

class EventLoop
{
    this()
    {
        zsys_handler_reset ();
        zsys_handler_set (null);
        
        ev_loop = ev_default_loop(EVFLAG_AUTO);
        assert(ev_loop);

        ev_signal_init (&m_signal_watcher, &sigint_cb, SIGINT);

        version(assert)
        {
            ev_timer_init (&m_reference_counter_timer, &count_reference_cb, 0, 3);
            ev_timer_again (ev_loop, &m_reference_counter_timer);
        }

        //ev_timer_init (&m_gc_timer, &gc_collect_cb, 0., 0.300);

        zctx = zctx_new();
        assert(zctx);
        
        //zctx_set_linger (context, 10);
        zloop = zloop_new();
    }

    ~this()
    {
        zctx_destroy(&zctx);
    }

    void info()
    {
        int zmqMajor, zmqMinor, zmqPatch;
        zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
        string zmqVersion = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
        log.info("ZMQ version : ", zmqVersion);

        int evMajor = ev_version_major();
        int evMinor = ev_version_minor();
        string evVersion = format("%s.%s", evMajor, evMinor);
        log.info("Libev version : ", evVersion);
    }

    void run()
    {
        ev_signal_start (ev_loop, &m_signal_watcher);

        //GC.disable();
        //scope(exit) GC.enable();
        ev_run(loop, 0);
    }

    auto loop()
    {
        return ev_loop;
    }

    auto context()
    {
        return zctx;
    }

    private
    {
        ev_signal m_signal_watcher;
        ev_timer m_reference_counter_timer;
        ev_timer m_gc_timer;

        ev_loop_t * ev_loop;
        zctx_t * zctx;
        zloop_t * zloop;
    }

    private extern(C)
    {
        static void gc_collect_cb (ev_loop_t * loop, ev_timer * w, int revents)
        {
            //GC.collect();
        }

        static void sigint_cb (ev_loop_t * loop, ev_signal * w, int revents)
        {
            ev_break(loop, EVBREAK_ALL);
        }

        static void count_reference_cb (ev_loop_t * loop, ev_timer * w, int revents)
        {
            log.info("\nReference counting : ");
            import http.server.Connection;
            log.info("Connection alive : ", Connection.alive());
            import http.protocol.Message;
            log.info("Message alive : ", Message.alive());
            //import http.protocol.Transaction;
            //log.info("Transaction alive : ", Transaction.alive());
            import http.server.Route;
            log.info("Route alive : ", Route.alive());
            import http.server.VirtualHost;
            log.info("VirtualHost alive : ", VirtualHost.alive());
            log.info("VirtualHostConfig alive : ", VirtualHostConfig.alive());
        }
    }
}
