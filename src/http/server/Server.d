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
        Connection connection;
        Server server;
    }

    VirtualHostConfig virtualHostConfig;
    ushort[] ports;
    string[] interfaces;
    Config config;
    Duration keepAliveDuration;
    
    this(
        ev_loop_t * loop,
        string[] interfaces, 
        ushort[] ports, 
        VirtualHostConfig virtualHostConfig,
        Config config)
    {
        mixin(Tracer);
        this.config = config;
        this.interfaces = interfaces;
        this.ports = ports;
        this.virtualHostConfig = virtualHostConfig;

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

                listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                /*
                Linger l;
                l.on = 1;
                l.time = 1;
                listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, l);
                listenerPoller.socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
                */

                listenerPoller.socket.bind(new InternetAddress(netInterface, port));
                listenerPoller.socket.blocking = false;
                listenerPoller.socket.listen(config[Parameter.BACKLOG].get!(int));
                GC.addRoot(cast(void*)listenerPoller);
                GC.setAttr(cast(void*)listenerPoller, GC.BlkAttr.NO_MOVE);

                ev_io_init(&listenerPoller.io, &handleConnection, listenerPoller.socket.handle(), EV_READ);
                ev_io_start(loop, &listenerPoller.io);
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
                auto connectionPoller = new ConnectionPoller;
                auto acceptedSocket = listener.accept();

                acceptedSocket.blocking = false;
                acceptedSocket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
                connectionPoller.connection = new Connection(acceptedSocket, listenerPoller.server.config);
                connectionPoller.server = listenerPoller.server;

                GC.addRoot(cast(void*)connectionPoller);
                //GC.setAttr(cast(void*)connectionPoller, GC.BlkAttr.NO_MOVE);

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
                connectionPoller.connection.handleRequest(connectionPoller.server.virtualHostConfig);
                if(!connectionPoller.connection.isValid())
                {
                    ev_io_stop(loop, &connectionPoller.io);

                    //delete connectionPoller;
                    //GC.free(connectionPoller);

                    connectionPoller.connection.shutdown();
                    //connectionPoller.connection.close();
                    
                    //GC.free(connectionPoller);
                    
                    GC.removeRoot(connectionPoller);
                    //GC.clrAttr(cast(void*)connectionPoller, GC.BlkAttr.NO_MOVE);
                }
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }
    }
}
