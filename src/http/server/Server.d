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
import http.server.Poller;

import http.protocol.Header;
import http.protocol.Response;
import http.protocol.Request;
import http.protocol.Status;

import EventLoop;

class Server
{
    Config m_config;
    ev_loop_t * m_loop;
    
    @property auto loop()
    {
        return m_loop;
    }

    @property auto config()
    {
        return m_config;
    }

    @property auto options()
    {
        return m_config.options;
    }

    this(ev_loop_t * loop, Config config)
    {
        mixin(Tracer);
        this.m_loop = loop;
        this.m_config = config;
        
        foreach(address ; config.addresses)
        {
            log.info("Listening on : ", address);
            
            auto listenerPoller = new ListenerPoller;
            listenerPoller.socket = new TcpSocket;
            listenerPoller.server = this;

            listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, m_config.options[Parameter.TCP_REUSEADDR].get!(bool));
            enum REUSEPORT = 15;
            listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption)REUSEPORT, m_config.options[Parameter.TCP_REUSEPORT].get!(bool));
            listenerPoller.socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, m_config.options[Parameter.TCP_NODELAY].get!(bool));

            if(m_config.options[Parameter.TCP_LINGER].get!(bool))
            {
                Linger linger;
                linger.on = 1;
                linger.time = 1;
                listenerPoller.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, linger);
            }

            listenerPoller.socket.bind(address);
            listenerPoller.socket.blocking = false;
            listenerPoller.socket.listen(m_config.options[Parameter.BACKLOG].get!(int));

            GC.addRoot(cast(void*)listenerPoller);
            GC.setAttr(cast(void*)listenerPoller, GC.BlkAttr.NO_MOVE);

            ev_io_init(&listenerPoller.io, &handleConnection, listenerPoller.socket.handle(), EV_READ);
            ev_set_priority (&listenerPoller.io, EV_MINPRI);
            ev_io_start(m_loop, &listenerPoller.io);
            
        }
    }

    static extern(C) 
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
                acceptedSocket.blocking = false;
                acceptedSocket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, listenerPoller.server.options[Parameter.TCP_NODELAY].get!(bool));

                auto connectionPoller = new ConnectionPoller(
                    listenerPoller.server, 
                    new Connection(acceptedSocket, listenerPoller.server.config),
                    &handleRequest);
                log.trace("Handling connection on ", listener.handle(), ", new connection on ", connectionPoller.connection.handle());
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
                        log.trace("connection shot down");
                        connectionPoller.shutdown();
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

class ServerWorker : Thread
{
    this(Config config)
    {
        super(&run);
        m_loop = new LibevLoop();
        m_server = new Server(m_loop.loop(), config);
    }

    void run()
    {
        mixin(Tracer);
        m_loop.run();
    }
    
    private LibevLoop m_loop;
    private Server m_server;
}
