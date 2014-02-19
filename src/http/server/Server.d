module http.server.Server;

import std.socket;
import std.file;
import std.parallelism;
import core.thread;
import core.time;

import dlog.Logger;

import interruption.Interruptible;

import http.server.Connection;
import http.server.Host;
import http.server.Config;

import http.protocol.Header;
import http.protocol.Response;
import http.protocol.Request;
import http.protocol.Status;

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
        log.trace("Connection handler for ", connection.getAddress(), " ended");
    }

    Interruptible parent;
    Connection connection;
    Host[] hosts;
    Host defaultHost;
}

class Listener : Interruptible
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
                        connectionThreads ~= connectionHandler;
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

    ~this()
    {
        foreach(listener ; listeners)
        {
            listener.close();
        }
    }
}

class Server : Interruptible
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
    
        this(string[] interfaces, 
             ushort[] ports, 
             Host[] hosts,
             Host defaultHost,
             Config config)
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

