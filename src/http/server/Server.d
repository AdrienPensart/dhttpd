module http.server.Server;

import std.socket;
import std.file;
import std.parallelism;
import core.thread;
import core.time;

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

import core.sys.posix.fcntl;
import core.sys.linux.epoll;
import core.sys.posix.unistd;
import core.sys.posix.sys.socket;
import core.stdc.errno;

import czmq;
import zsys;

interface Runnable
{
    void run();
}

void setblocking(int sock, bool byes)
{
    int x = fcntl(sock, F_GETFL, 0);
    if(-1 == x)
        goto err;
    if(byes)
        x &= ~O_NONBLOCK;
    else
        x |= O_NONBLOCK;
    if(-1 == fcntl(sock, F_SETFL, x))
        goto err;
    return;
    err:
        throw new SocketOSException("Unable to set socket blocking");
}

/*
class ServerEvent
{
    alias void function(ServerEvent) Handler;
    Handler handler;
    Socket socket;
    Server server;
    Connection connection;
}

void handleConnectionExtern(ServerEvent serverEvent)
{
    serverEvent.server.handleConnection(serverEvent.socket);
}

void handleRequestExtern(ServerEvent serverEvent)
{
    serverEvent.server.handleRequest(serverEvent.connection);
}
*/

class Server : Interruptible, Runnable
{
    VirtualHost[] hosts;
    VirtualHost defaultHost;
    
    epoll_event[10] events;
    epoll_event event;
    Socket[] listeners;
    //Connection[int] connections;
    //ServerEvent[int] serverEvents;
    
    ushort[] ports;
    string[] interfaces;
    Config config;
    Duration keepAliveDuration;
    int efd;
    
    this(
            string[] interfaces, 
            ushort[] ports, 
            VirtualHost[] hosts,
            VirtualHost defaultHost,
            Config config
        )
    {
        this.config = config;
        this.interfaces = interfaces;
        this.ports = ports;
        this.hosts = hosts;
        this.defaultHost = defaultHost;
        efd = epoll_create1 (0);
        if (efd == -1)
        {
            log.fatal("epoll creation failed");
        }
        
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
                    auto listener = new TcpSocket;                    
                    listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                    /*
                    Linger l;
                    l.on = 1;
                    l.time = 1;
                    listener.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, l);
                    listener.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
                    */
                    listener.bind(new InternetAddress(port));                   
                    listener.listen(config[Parameter.BACKLOG].get!(int));
                    listener.blocking = false;
                    
                    /*
                    ServerEvent serverEvent = new ServerEvent();
                    serverEvent.handler = &handleConnectionExtern;
                    serverEvent.socket = listener;
                    serverEvent.server = this;
                    */
                    event.events = EPOLLIN;
                    event.data.fd = listener.handle();
                    
                    log.info("add listener with epoll_ctl, fd = ", listener.handle());
                    int status = epoll_ctl (efd, EPOLL_CTL_ADD, event.data.fd, &event);
                    if (status != 0)
                    {
                        log.fatal("epoll ctl failed, : ", lastSocketError());
                    }
                    listeners ~= listener;
                    //serverEvents[listener.handle()] = serverEvent;
                }
                catch(SocketOSException e)
                {
                    log.error("Can't bind to port ", port, ", reason : ", e);
                }
            }
        }
    }

    ~this()
    {
        /*
        foreach(listener ; listeners)
        {
            listener.close();
        }
        */
    }
    
    /*
    void remove(int fd)
    {
        if (epoll_ctl(efd, EPOLL_CTL_DEL, fd, null) < 0)
	    {
            log.error("epoll_ctl : ", lastSocketError());
        }
        else
        {
	        ServerEvent serverEvent = serverEvents[fd];
            serverEvent.connection.close();
            if(!serverEvents.remove(fd))
            {
                log.error("can't remove serverEvent from AA");
            }
        }
    }
    */
    
    void run()
    {
        mixin(Tracer);
        while(!interrupted())
        {
            int n = epoll_wait (efd, events.ptr, cast(int)events.length, -1);
            if(n > 0)
            {
                polling: for (int i = 0; i < n; i++)
    	        {
   	                int fd = events[i].data.fd;
        	        log.info("i = ", i, ", fd = ", fd, ", events : ", events[i].events);
	                if ((events[i].events & EPOLLRDHUP) ||
	                    (events[i].events & EPOLLERR) ||
                        (events[i].events & EPOLLHUP)/* ||
                        (!(events[i].events & EPOLLIN))*/)
	                {
	                    log.error("not epollin, epoll error on fd = ", fd, " : ", lastSocketError());
	                    //auto connection = connections[fd];
	                    /*
	                    log.info("deleting connection with fd = ", fd);
                        if (epoll_ctl(efd, EPOLL_CTL_DEL, fd, null) < 0)
	                    {
                            log.error("epoll_ctl : ", lastSocketError());
                        }
                        */
                        //connection.close();
                        //connections.remove(fd);
                        /*
                        if (epoll_ctl(efd, EPOLL_CTL_DEL, fd, null) < 0)
	                    {
                            log.error("epoll_ctl : ", lastSocketError());
                        }
                        */
                        shutdown(fd, 2);
                        close(fd);
	                }
	                else if(events[i].events & EPOLLIN)
	                {
	                    log.info("EPOLLIN from fd = ", fd);
                        foreach(listener ; listeners)
                        {
                            if(fd == listener.handle())
                            {
                                auto newsock = .accept(listener.handle(), null, null);
                                if(socket_t.init == newsock)
                                {
                                    log.info("accept error : ", lastSocketError());
                                }
                                
                                setblocking(newsock, false);
                                event.events = EPOLLIN;
                                event.data.fd = newsock;
                                log.info("epoll_ctl, new socket fd = ", event.data.fd, " events = ", event.events);
                                int status = epoll_ctl (efd, EPOLL_CTL_ADD, event.data.fd, &event);
                                if (status == -1)
                                {
                                    log.fatal("epoll_ctl error");
                                }
                                continue polling;
                            }
                        }
                        
                        log.info("handling new request with fd = ", fd);
                        SocketFlags flags = SocketFlags.NONE;
                        string buf = "HTTP/1.0 200 Ok\r\nServer: dhttpd\r\nConnection: close\r\nContent-Type: text/html\r\nContent-Length: 5\r\n\r\nHello";
                        send(fd, buf.ptr, buf.length, cast(int)flags);
                        /*
                        if (epoll_ctl(efd, EPOLL_CTL_DEL, fd, null) < 0)
	                    {
                            log.error("epoll_ctl : ", lastSocketError());
                        }
                        */
                        shutdown(fd, 2);
                        close(fd);
                        
                        /*
                        connection.handleRequest(hosts, defaultHost);
                        if(!connection.isValid())
                        {
                            log.info("closing ", connection.getAddress());
                            
                            log.info("deleting connection with fd = ", fd);
                            if (epoll_ctl(efd, EPOLL_CTL_DEL, fd, null) < 0)
	                        {
                                log.error("epoll_ctl : ", lastSocketError());
                            }
                            
                            connection.close();
                            connections.remove(fd);
                        }
                        */
            	    }
            	    else
            	    {
            	        log.error("unknow error from fd = ", fd, " : ", lastSocketError());
            	        //remove(events[i].data.fd);
            	        if (epoll_ctl(efd, EPOLL_CTL_DEL, fd, null) < 0)
	                    {
                            log.error("epoll_ctl : ", lastSocketError());
                        }
                        
                        shutdown(fd, 2);
                        close(fd);
            	    }
            	}
            }
        }
    }
    /*
    void handleConnection(Socket listener)
    {
        mixin(Tracer);
        log.info("handle new connection");
        auto acceptedSocket = listener.accept();
        //acceptedSocket.blocking = false;
        //acceptedSocket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);

        ServerEvent serverEvent = new ServerEvent();
        serverEvent.socket = acceptedSocket;
        serverEvent.handler = &handleRequestExtern;
        serverEvent.server = this;
        serverEvent.connection = new Connection(acceptedSocket, config);
        
        epoll_event event;
        event.events = EPOLLIN; // | EPOLLET;
        event.data.fd = acceptedSocket.handle();
        
        int status = epoll_ctl (efd, EPOLL_CTL_ADD, acceptedSocket.handle(), &event);
        if (status == -1)
        {
            log.fatal("epoll_ctl error");
        }
        serverEvents[acceptedSocket.handle()] = serverEvent;
    }
    
    void handleRequest(Connection connection)
    {
        mixin(Tracer);
        log.info("handle new request");
        connection.handleRequest(hosts, defaultHost);
        if(!connection.isValid())
        {
            int fd = connection.getHandle().handle();
            remove(fd);
        }
    }
    */
}


/*
extern(C) int AcceptHandler(zloop_t* loop, zmq_pollitem_t* item, void* arg)
{
    Poller poller = cast(Poller)arg;
    poller.newConnection(item);
    return 0;
}

extern(C) int RequestHandler(zloop_t* loop, zmq_pollitem_t* item, void* arg)
{
    Poller poller = cast(Poller)arg;
    poller.handleConnection(item);
    return 0;
}

class Poller : Interruptible, Runnable
{
    VirtualHost[] hosts;
    VirtualHost defaultHost;
    Socket[int] listeners;
    Connection[int] connections;

    ushort[] ports;
    string[] interfaces;
    Config config;
    Duration keepAliveDuration;

    zctx_t * context;
    zloop_t * loop;
    //zmq_pollitem_t*[] polls;

    this(
            string[] interfaces, 
            ushort[] ports, 
            VirtualHost[] hosts,
            VirtualHost defaultHost,
            Config config
        )
    {
        context = zctx_new();        
        //zctx_set_linger (context, 10);

        loop = zloop_new();
        //zloop_set_verbose (loop, true);

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
                    auto listener = new TcpSocket;
                    listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                    
                    Linger l;
                    l.on = 1;
                    l.time = 1;

                    listener.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, l);
                    listener.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);

                    listener.bind(new InternetAddress(port));
                    listener.blocking = false;                    
                    listener.listen(config[Parameter.BACKLOG].get!(int));
                    listeners[listener.handle()] = listener;

                    auto pollitem = new zmq_pollitem_t();
                    pollitem.fd = listener.handle();
                    pollitem.events = ZMQ_POLLIN;
                    
                    auto rc = zloop_poller (loop, pollitem, &AcceptHandler, cast(void*)this);
                    enforce(rc == 0);

                    //polls ~= pollitem;

                }
                catch(SocketOSException e)
                {
                    log.error("Can't bind to port ", port, ", reason : ", e);
                }
            }
        }
    }

    ~this()
    {
        log.info("Left connections length : ", connections.length);
        foreach(listener ; listeners)
        {
            listener.close();
        }
        zloop_destroy(&loop);
        zctx_destroy(&context);
    }

    void newConnection(zmq_pollitem_t * item)
    {
        mixin(Tracer);
        try
        {
            log.trace("New connection");
            auto listener = listeners[item.fd];
            auto acceptedSocket = listener.accept();
            acceptedSocket.blocking = false;
            acceptedSocket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);

            auto connection = new Connection(acceptedSocket, config);
            connections[acceptedSocket.handle()] = connection;

            auto pollitem = new zmq_pollitem_t();
            pollitem.fd = acceptedSocket.handle();
            pollitem.events = ZMQ_POLLIN;

            auto rc = zloop_poller (loop, pollitem, &RequestHandler, cast(void*)this);
            //enforce(rc == 0);
            //polls ~= pollitem;
        }
        catch(Exception e)
        {
            log.error(e);
        }
    }

    void handleConnection(zmq_pollitem_t * item)
    {
        mixin(Tracer);
        try
        {
            auto connection = connections[item.fd];
            connection.handleRequest(hosts, defaultHost);
            if(!connection.isValid())
            {
                zloop_poller_end(loop, item);
                connection.close();
                connections.remove(item.fd);
            }
        }
        catch(Exception e)
        {
            log.error(e);
        }
    }

    void run()
    {
        while(!interrupted())
        {
            int zloopResult = zloop_start (loop);
            if(zloopResult == 0)
            {
                handleInterruption();
            }
            else if(zloopResult == -1)
            {
                log.info("interrupted by handler");
            }
            else
            {
                log.info("interrupted by unknown event");
            }
        }
    }
}
*/

