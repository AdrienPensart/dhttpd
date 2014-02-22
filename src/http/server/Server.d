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

import czmq;
import zsys;

interface Runnable
{
    void run();
}

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

        import std.stdio;
        writeln("destructor");
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

/*
class ConnectionHandler : Thread
{
    this(Interruptible parent, Connection connection, Host[] hosts, Host defaultHost)
    {
        this.parent = parent;
        this.connection = connection;
        this.hosts = hosts;
        this.defaultHost = defaultHost;
        super(&run);
    }

    private void run()
    {
        mixin(Tracer);
        while(!parent.interrupted())
        {
            log.trace("Waiting request");
            State state = connection.handleRequest();
            if(state == State.INTERRUPTED || state == State.CLOSED)
            {
                break;
            }
            else if(state == State.REQUEST)
            {
                connection.routeRequest(hosts, defaultHost);
            }
        }
        //log.info("Connection handler for ", connection.getAddress(), " ended");
    }

    Interruptible parent;
    Connection connection;
    Host[] hosts;
    Host defaultHost;
}

class Listener : Interruptible, Runnable
{
    Host[] hosts;
    Host defaultHost;
    Socket[] listeners;
    ushort[] ports;
    string[] interfaces;
    Config config;
    Thread[] connectionThreads;
    Duration keepAliveDuration;

    this(
            string[] interfaces, 
            ushort[] ports, 
            Host[] hosts,
            Host defaultHost,
            Config config
        )
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
                    auto listener = new TcpSocket;
                    listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                    listener.bind(new InternetAddress(port));
                    listener.listen(config[Parameter.BACKLOG].get!(int));
                    listeners ~= listener;
                }
                catch(SocketOSException e)
                {
                    log.error("Can't bind to port ", port, ", reason : ", e.msg);
                }
            }
        }
    }

    ~this()
    {
        foreach(listener ; listeners)
        {
            listener.close();
        }
    }

    void run()
    {
        mixin(Tracer);
        while(!interrupted())
        {
            log.trace("Waiting connections");
            auto listenSet = new SocketSet(config[Parameter.MAX_CONNECTION].get!(int) + 1);
            foreach(listener ; listeners)
            {
                listenSet.add(listener);
            }

            auto status = Socket.select(listenSet, null, null);
            if (status == -1)
            {
                handleInterruption();
            }
            else
            {
                foreach(listener ; listeners)
                {
                    if(listenSet.isSet(listener))
                    {
                        auto acceptedSocket = listener.accept();
                        auto connection = new Connection(acceptedSocket, config);
                        auto connectionHandler = new ConnectionHandler(this, connection, hosts, defaultHost);
                        connectionHandler.start();
                        //connectionThreads ~= connectionHandler;
                    }
                }
            }
        }
        
        log.trace("Waiting for all threads to finish");
        foreach(connectionThread ; connectionThreads)
        {
            connectionThread.join();
        }
    }
}

class Server : Interruptible, Runnable
{
    private:

        //Listener listener;

        Host[] hosts;
        string[] interfaces;
        Socket[] listeners;
        ushort[] ports;
        Config config;
        Connection[] connections;
        SocketSet sset;
        Duration keepAliveDuration;
        Host defaultHost;

    public:
    
        this(
                string[] interfaces, 
                ushort[] ports, 
                Host[] hosts,
                Host defaultHost,
                Config config
            )
        {
            this.interfaces = interfaces;
            this.ports = ports;
            this.config = config;
            this.defaultHost = defaultHost;
            this.hosts = hosts;
            foreach(host; hosts)
            {
                host.addSupportedPorts(ports);
            }

            sset = new SocketSet(config[Parameter.MAX_CONNECTION].get!(int) + 1);
            createListeners();
        }

        ~this()
        {
            foreach(listener ; listeners)
            {
                listener.close();
            }
        }

        void run()
        {
            mixin(Tracer);
                
            if(!listeners.length)
            {
                log.fatal("No port to listen to.");
                return;
            }

            while(!interrupted())
            {
                try
                {
                    buildSocketSet();
                    selectSockets();        
                    handleReadyConnections();
                    cleanConnections();
                    pollListeners();
                }
                catch(SocketOSException e)
                {
                    log.error(e);
                    cleanConnections();
                }
            }
        }
        
    private:

        void buildSocketSet()
        {
            sset.reset();
            foreach(listener ; listeners)
            {
                sset.add(listener);
            }
            foreach(connection ; connections)
            {
                sset.add(connection.getHandle());
            }
        }

        void selectSockets()
        {
            //auto status = Socket.select(sset, null, null, dur!"seconds"(1));
            auto status = Socket.select(sset, null, null);
            if (status == -1)
            {
                handleInterruption();
            }
        }
    
        void handleReadyConnections()
        {
            mixin(Tracer);
            foreach(connection ; connections)
            {
                if(connection.isReady(sset))
                {
                    if(connection.handleRequest())
                    {
                        connection.routeRequest(hosts, defaultHost);
                    }
                }
            }
        }

        void cleanConnections()
        {
            mixin(Tracer);
            Connection[] aliveConnections;
            foreach(connection ; connections)
            {
                if(connection.isValid())
                {
                    aliveConnections ~= connection;
                }
                else
                {
                    connection.close();
                }
            }
            connections = aliveConnections;
        }
        
        void pollListeners()
        {
            mixin(Tracer);
            foreach(listener ; listeners)
            {
                if(sset.isSet(listener))
                {
                    acceptNewConnection(listener);
                }
            }
        }

        void acceptNewConnection(Socket listener)
        {
            mixin(Tracer);
            try
            {
                auto acceptedSocket = listener.accept();
                auto connection = new Connection(acceptedSocket, config);
                if (isTooManyConnections())
                {
                    log.warning("Rejected connection from ", connection.getAddress(), " too many connections.");
                    connection.close();
                }
                else
                {
                    connections ~= connection;
                    log.trace("Connection from ", connection.getAddress(), " established, ", connections.length, " active connections");
                }
            }
            catch (Exception e)
            {
                log.error("Error accepting: ", e.toString());
            }
        }

        void createListeners()
        {
            mixin(Tracer);
            foreach(netInterface ; interfaces)
            {
                log.info("Listening on ports : ", ports, " on interface ", netInterface);
                foreach(port ; ports)
                {
                    try
                    {
                        auto listener = new TcpSocket;
                        listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                        listener.bind(new InternetAddress(port));
                        listener.listen(config[Parameter.BACKLOG].get!(int));
                        listeners ~= listener;
                    }
                    catch(SocketOSException e)
                    {
                        log.error("Can't bind to port ", port, ", reason : ", e.msg);
                    }
                }
            }
        }

        bool isTooManyConnections()
        {
            return connections.length >= config[Parameter.MAX_CONNECTION].get!(int);
        }
}
*/
