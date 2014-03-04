module http.server.Server;

import std.socket;
import std.file;
import core.thread;
import core.time;
import core.memory;

import dlog.Logger;

import http.server.Connection;
import http.server.VirtualHost;
import http.server.Config;
import http.server.Transaction;

import http.protocol.Header;
import http.protocol.Response;
import http.protocol.Request;
import http.protocol.Status;

import libev.ev;

class Server
{
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

        void updateEvents(int events)
        {
            ev_io_stop(server.loop, &io);
            ev_io_set(&io, connection.handle(), events);
            ev_io_start(server.loop, &io);
        }
    }

    VirtualHostConfig virtualHostConfig;
    ushort[] ports;
    string[] interfaces;
    Config config;
    Duration keepAliveDuration;
    ev_loop_t * loop;

    this(
        ev_loop_t * loop,
        string[] interfaces, 
        ushort[] ports, 
        VirtualHostConfig virtualHostConfig,
        Config config)
    {
        mixin(Tracer);
        this.loop = loop;
        this.config = config;
        this.interfaces = interfaces;
        this.ports = ports;
        this.virtualHostConfig = virtualHostConfig;
        Transaction.enable_cache(config[Parameter.HTTP_CACHE].get!(bool));

        foreach(host; virtualHostConfig.hosts)
        {
            host.addSupportedPorts(ports);
        }

        foreach(netInterface ; interfaces)
        {
            log.info("Listening on ports : ", ports, " on interface ", netInterface);
            foreach(port ; ports)
            {
                auto listenerPoller = new ListenerPoller;
                listenerPoller.socket = new TcpSocket;
                listenerPoller.server = this;

                listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, config[Parameter.TCP_REUSEADDR].get!(bool));
                listenerPoller.socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, config[Parameter.TCP_NODELAY].get!(bool));

                if(config[Parameter.TCP_LINGER].get!(bool))
                {
                    Linger linger;
                    linger.on = 1;
                    linger.time = 1;
                    listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, linger);
                }

                listenerPoller.socket.bind(new InternetAddress(netInterface, port));
                listenerPoller.socket.blocking = false;
                listenerPoller.socket.listen(config[Parameter.BACKLOG].get!(int));

                GC.addRoot(cast(void*)listenerPoller);
                GC.setAttr(cast(void*)listenerPoller, GC.BlkAttr.NO_MOVE);

                ev_io_init(&listenerPoller.io, &handleConnection, listenerPoller.socket.handle(), EV_READ);
                ev_set_priority (&listenerPoller.io, EV_MINPRI);
                ev_io_start(loop, &listenerPoller.io);
            }
        }
    }

    static extern(C) 
    {
        void shutdown(ConnectionPoller * poller)
        {
            ev_io_stop(poller.server.loop, &poller.io);
            ev_timer_stop(poller.server.loop, &poller.timer_io);
            poller.connection.shutdown();
            GC.removeRoot(poller);
            GC.clrAttr(cast(void*)poller, GC.BlkAttr.NO_MOVE);
        }

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
                acceptedSocket.blocking = false;
                acceptedSocket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, listenerPoller.server.config[Parameter.TCP_NODELAY].get!(bool));

                auto connectionPoller = new ConnectionPoller;
                connectionPoller.connection = new Connection(acceptedSocket, listenerPoller.server.config);
                connectionPoller.server = listenerPoller.server;

                log.trace("Handling connection on ", listener.handle(), ", new connection on ", acceptedSocket.handle());
                GC.addRoot(cast(void*)connectionPoller);
                GC.setAttr(cast(void*)connectionPoller, GC.BlkAttr.NO_MOVE);

                ev_io_init(&connectionPoller.io, &handleRequest, acceptedSocket.handle(), EV_READ);
                ev_set_priority(&connectionPoller.io, EV_MAXPRI);
                ev_io_start(loop, &connectionPoller.io);

                auto duration = listenerPoller.server.config[Parameter.KEEP_ALIVE_TIMEOUT].get!(Duration);
                connectionPoller.timer_io.data = cast(void*)connectionPoller;
                ev_timer_init (&connectionPoller.timer_io, &connectionTimeout, 0., cast(double)duration.seconds());
                ev_set_priority (&connectionPoller.timer_io, EV_MINPRI);
                ev_timer_again (loop, &connectionPoller.timer_io);
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
                    if(!connectionPoller.connection.synctreat(connectionPoller.server.virtualHostConfig))
                    {
                        shutdown(connectionPoller);
                    }
                }
                /*
                if(EV_READ & revents)
                {
                    log.trace("Receiving request on ", connectionPoller.connection.handle());
                    if(connectionPoller.connection.recv(connectionPoller.server.virtualHostConfig))
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
                shutdown(connectionPoller);
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }
    }
}
