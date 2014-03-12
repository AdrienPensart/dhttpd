module http.server.Poller;

import deimos.ev;

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

    this(Server server, InternetAddress address)
    {
        this.server = server;

        socket = new TcpSocket;
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, server.config.options[Parameter.TCP_REUSEADDR].get!(bool));
        enum REUSEPORT = 15;
        socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption)REUSEPORT, server.config.options[Parameter.TCP_REUSEPORT].get!(bool));
        enum TCP_DEFER_ACCEPT = 9;
        socket.setOption(SocketOptionLevel.TCP, cast(SocketOption)TCP_DEFER_ACCEPT, server.config.options[Parameter.TCP_DEFER].get!(bool));

        socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
        Linger linger;
        linger.on = 1;
        linger.time = 1;
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, linger);

        socket.bind(address);
        socket.blocking = false;
        socket.listen(server.config.options[Parameter.BACKLOG].get!(int));

        ev_io_init(&io, &handleConnection, socket.handle(), EV_READ);
        ev_set_priority (&io, EV_MINPRI);
        ev_io_start(server.loop, &io);

        GC.addRoot(cast(void*)&this);
        GC.setAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
    }

    private static extern(C) 
    {
        void handleConnection(ev_loop_t *loop, ev_io * watcher, int revents)
        {
            try
            {
                mixin(Tracer);
                auto listenerPoller = cast(ListenerPoller *)watcher;
                if(EV_ERROR & revents)
                {
                    log.error("Listener in error.");
                    return;
                }
                auto listener = listenerPoller.socket;
                auto acceptedSocket = listener.accept();
                log.trace("Handling connection on ", listener.handle(), ", new connection on ", acceptedSocket.handle());

                auto connection = new Connection(acceptedSocket, listenerPoller.server.config);
                auto connectionPoller = new ConnectionPoller(listenerPoller.server, connection);
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }
    }
}

struct ConnectionPoller
{    
    ev_io io;
    ev_timer timer_io;
    Connection connection;
    Server server;

    this(Server server, Connection connection)
    {
        mixin(Tracer);
        this.server = server;
        this.connection = connection;

        ev_io_init(&io, &handleRequest, connection.handle(), EV_READ);
        ev_set_priority(&io, EV_MAXPRI);
        ev_io_start(server.loop, &io);

        timer_io.data = cast(void*)&this;

        auto duration = server.options[Parameter.KEEP_ALIVE_TIMEOUT].get!(Duration);
        ev_timer_init (&timer_io, &connectionTimeout, 0., cast(double)duration.seconds());
        ev_set_priority (&timer_io, EV_MINPRI);
        ev_timer_again (server.loop, &timer_io);

        GC.addRoot(cast(void*)&this);
        GC.setAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
    }

    void updateEvents(int events)
    {
        mixin(Tracer);
        ev_io_stop(server.loop, &io);
        ev_io_set(&io, connection.handle(), events);
        ev_io_start(server.loop, &io);
    }

    void release()
    {
        mixin(Tracer);
        log.trace("Shuting down : ", connection.handle());

        //connection.shutdown();
        connection.close();

        ev_io_stop(server.loop, &io);
        ev_timer_stop(server.loop, &timer_io);
        
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
                /*
                if(EV_READ & revents)
                {
                    log.trace("Receiving request on ", connectionPoller.connection.handle());
                    if(connectionPoller.connection.recv())
                    {
                        ev_timer_again (loop, &connectionPoller.timer_io);
                        if(!connectionPoller.connection.empty())
                        {
                            log.trace("Activating response on ", connectionPoller.connection.handle());
                            connectionPoller.updateEvents(EV_WRITE | EV_READ);
                        }
                    }
                }

                if(EV_WRITE & revents)
                {
                    log.trace("Sending response on ", connectionPoller.connection.handle());
                    if(connectionPoller.connection.send())
                    {
                        ev_timer_again (loop, &connectionPoller.timer_io);
                        if(connectionPoller.connection.empty())
                        {
                            log.trace("Empty queue after sending response");
                            connectionPoller.updateEvents(EV_READ);
                        }
                    }
                }
                
                if(!connectionPoller.connection.valid())
                {
                    log.trace("Connection terminated.");
                    shutdown(connectionPoller);
                }
                */
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }
    }
}
