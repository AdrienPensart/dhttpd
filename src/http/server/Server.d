 module http.server.Server;

import std.socket;
import std.file;
import std.parallelism;
import core.thread;
import core.time;
import core.memory;

import dlog.Logger;

import interruption.Manager;
import interruption.Interruptible;

import http.server.Connection;
import http.server.VirtualHost;
import http.server.Config;

import http.protocol.Header;
import http.protocol.Response;
import http.protocol.Request;
import http.protocol.Status;

import czmq;
import zsys;
import libev.ev;
import std.c.stdlib;

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
        Connection connection;
        Server server;
    }

    VirtualHost[] hosts;
    VirtualHost defaultHost;
    ushort[] ports;
    string[] interfaces;
    Config config;
    Duration keepAliveDuration;
    //TcpSocket[] listeners;

    //Poller[int] pollers;
    //Socket[int] listeners;

    this(
        ev_loop_t * loop,
        string[] interfaces, 
        ushort[] ports, 
        VirtualHost[] hosts,
        VirtualHost defaultHost,
        Config config)
    {
        this.config = config;
        this.interfaces = interfaces;
        this.ports = ports;
        this.hosts = hosts;
        this.defaultHost = defaultHost;

        foreach(host; hosts)
        {
            host.addSupportedPorts(ports);
        }

        foreach(netInterface ; interfaces)
        {
            log.info("Listening on ports : ", ports, " on interface ", netInterface);
            foreach(port ; ports)
            {
                try
                {
                    //auto listenerPoller = cast(ListenerPoller*)malloc(ListenerPoller.sizeof);
                    auto listenerPoller = new ListenerPoller;
                    listenerPoller.socket = new TcpSocket;
                    listenerPoller.server = this;
                    listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                    /*
                    Linger l;
                    l.on = 1;
                    l.time = 1;

                    listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, l);
                    listenerPoller.socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
                    */
                    listenerPoller.socket.bind(new InternetAddress(port));
                    listenerPoller.socket.blocking = false;
                    listenerPoller.socket.listen(config[Parameter.BACKLOG].get!(int));

                    GC.addRoot(cast(void*)listenerPoller);
                    GC.setAttr(cast(void*)listenerPoller, GC.BlkAttr.NO_MOVE);

                    ev_io_init(&listenerPoller.io, &handleConnection, listenerPoller.socket.handle(), EV_READ);
                    ev_io_start(loop, &listenerPoller.io);
                }
                catch(SocketOSException e)
                {
                    log.error("Can't bind to port ", port, ", reason : ", e);
                }
            }
        }
    }

    extern(C) 
    {
        static void handleConnection(ev_loop_t *loop, ev_io * watcher, int revents)
        {
            try
            {
                mixin(Tracer);
                if(EV_ERROR & revents)
                {
                    log.error("got invalid event");
                    return;
                }
                log.trace("handling connection on ", watcher.fd);

                auto listenerPoller = cast(ListenerPoller *)watcher;
                auto listener = listenerPoller.socket;
                auto acceptedSocket = listener.accept();
                acceptedSocket.blocking = false;
                //acceptedSocket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);

                //Poller * newPoller = cast(Poller*)malloc(Poller.sizeof);
                auto connectionPoller = new ConnectionPoller;

                //connectionPoller.socket = acceptedSocket;
                connectionPoller.connection = new Connection(acceptedSocket, listenerPoller.server.config);
                connectionPoller.server = listenerPoller.server;

                GC.addRoot(cast(void*)connectionPoller);
                GC.setAttr(cast(void*)connectionPoller, GC.BlkAttr.NO_MOVE);

                ev_io_init(&connectionPoller.io, &handleRequest, acceptedSocket.handle(), EV_READ);
                ev_io_start(loop, &connectionPoller.io);
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }

        static void handleRequest(ev_loop_t *loop, ev_io * watcher, int revents)
        {
            try
            {
                mixin(Tracer);
                if(EV_ERROR & revents)
                {
                    log.error("got invalid event");
                    return;
                }
                log.trace("handling request on ", watcher.fd);

                auto connectionPoller = cast(ConnectionPoller *)watcher;
                if(connectionPoller.connection.isValid())
                {
                    connectionPoller.connection.handleRequest(connectionPoller.server.hosts, connectionPoller.server.defaultHost);
                    if(!connectionPoller.connection.isValid())
                    {
                        ev_io_stop(loop, &connectionPoller.io);
                        connectionPoller.connection.close();

                        GC.removeRoot(connectionPoller);
                        GC.clrAttr(connectionPoller, GC.BlkAttr.NO_MOVE);
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
