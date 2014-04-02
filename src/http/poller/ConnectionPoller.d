module http.poller.ConnectionPoller;

import deimos.ev;
import std.socket;

import dlog.Logger;
import crunch.ManualMemory;
import http.Connection;
import http.Config;
import http.Options;
import http.Server;
import http.Connection;

struct ConnectionPoller
{
    ev_io io;
    ev_timer timer_io;
    Connection connection;
    Server server;

    mixin ManualMemory;

    this(Server server, Connection connection)
    {
        mixin(Tracer);
        this.server = server;
        this.connection = connection;
        configurePoller();
        acquireMemory();
    }

    private void configurePoller()
    {
        mixin(Tracer);
        ev_io_init(&io, &handleRequest, connection.handle(), EV_READ);
        ev_set_priority(&io, EV_MAXPRI);
        ev_io_start(server.loop.loop(), &io);

        timer_io.data = cast(void*)&this;

        auto duration = server.options[Parameter.KEEP_ALIVE_TIMEOUT].get!(Duration);
        ev_timer_init (&timer_io, &connectionTimeout, 0., cast(double)duration.seconds());
        ev_set_priority (&timer_io, EV_MINPRI);
        ev_timer_again (server.loop.loop(), &timer_io);
    }

    private void updateEvents(int events)
    {
        mixin(Tracer);
        ev_io_stop(server.loop.loop(), &io);
        ev_io_set(&io, connection.handle(), events);
        ev_io_start(server.loop.loop(), &io);
    }

    private void release()
    {
        mixin(Tracer);
        log.trace("Shuting down : ", connection.handle());

        ev_io_stop(server.loop.loop(), &io);
        ev_timer_stop(server.loop.loop(), &timer_io);

        connection.shutdown();
        connection.close();

        releaseMemory();
    }

    private static extern(C) 
    {
        void connectionTimeout(ev_loop_t * loop, ev_timer * watcher, int revents)
        {
            try
            {
                mixin(Tracer);
                auto connectionPoller = cast(ConnectionPoller *)watcher.data;
                if(EV_ERROR & revents)
                {
                    log.error("Connection in error.");
                    return;
                }
                log.trace("Connection timeout on ", connectionPoller.connection.handle());
                connectionPoller.release();
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }

        void handleRequest(ev_loop_t *loop, ev_io * watcher, int revents)
        {
            try
            {
                mixin(Tracer);
                auto connectionPoller = cast(ConnectionPoller *)watcher;
                if(EV_ERROR & revents)
                {
                    log.error("Connection in error on ", connectionPoller.connection.handle());
                    return;
                }

                if(EV_READ & revents)
                {
                    ev_timer_again (loop, &connectionPoller.timer_io);
                    if(!connectionPoller.connection.synctreat())
                    {
                        connectionPoller.release();
                    }
                }
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }
    }
}
