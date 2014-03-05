module http.server.Poller;

import libev.ev;

import std.socket;
import core.memory;

import dlog.Logger;

import http.server.Config;
import http.server.Server;
import http.server.Connection;

alias extern(C) static void function(ev_loop_t *loop, ev_io * watcher, int revents) PollerCallback;

struct ListenerPoller
{
    ev_io io;
    Socket socket;
    Server server;
}

struct ConnectionPoller
{    
    ev_io io;
    ev_timer timer_io;
    Connection connection;
    Server server;

    this(Server server, Connection connection, PollerCallback pc)
    {
        this.server = server;
        this.connection = connection;

        ev_io_init(&io, pc, connection.handle(), EV_READ);
        ev_set_priority(&io, EV_MAXPRI);
        ev_io_start(server.loop(), &io);

        timer_io.data = cast(void*)&this;

        auto duration = server.config[Parameter.KEEP_ALIVE_TIMEOUT].get!(Duration);
        ev_timer_init (&timer_io, &connectionTimeout, 0., cast(double)duration.seconds());
        ev_set_priority (&timer_io, EV_MINPRI);
        ev_timer_again (server.loop(), &timer_io);

        GC.addRoot(cast(void*)&this);
        GC.setAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
    }

    void updateEvents(int events)
    {
        ev_io_stop(server.loop, &io);
        ev_io_set(&io, connection.handle(), events);
        ev_io_start(server.loop, &io);
    }

    void shutdown()
    {
        mixin(Tracer);
        log.trace("Shuting down : ", connection.handle());

        ev_io_stop(server.loop(), &io);
        ev_timer_stop(server.loop, &timer_io);
        
        connection.shutdown();
        GC.removeRoot(cast(void*)&this);
        GC.clrAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
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
                connectionPoller.shutdown();
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }
    }
}
