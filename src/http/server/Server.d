module http.server.Server;

import std.socket;
import std.file;
import core.thread;
import core.time;

import dlog.Logger;

import interruption.InterruptionException;

import http.server.Config;
import http.server.Connection;
import http.server.Host;
import http.server.Options;

import http.protocol.Header;
import http.protocol.Response;
import http.protocol.Request;
import http.protocol.Status;

class Server
{
    private:

        Host[] hosts;
        string[] interfaces;
        Socket[] listeners;
        ushort[] ports;
        Options options;
        string serverString;
        bool interrupted = false;
        Connection[] connections;
        SocketSet sset;
        Duration keepAliveDuration;

    public:
    
        this(string[] interfaces, 
             ushort[] ports, 
             Host[] hosts, 
             Options options=Config.getOptions(),
             string serverString=Config.getServerString())
        {
            this.interfaces = interfaces;
            this.ports = ports;

            this.hosts = hosts;
            foreach(host; hosts)
            {
                host.addSupportedPorts(ports);
            }

            this.options = options;
            this.serverString = serverString;
            keepAliveDuration = dur!"seconds"(options[Parameter.TIMEOUT]);
            sset = new SocketSet(options[Parameter.MAX_CONNECTION] + 1);
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

            while(!interrupted)
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
        
        void interrupt() nothrow
        {
            interrupted = true;
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
    
        void handleInterruption()
        {
            log.info("Select interrupted.");
            throw (interrupted ?
                new InterruptionException : 
                new InterruptionException("Select interrupted for unknow reason"));
        }

        void handleReadyConnections()
        {
            mixin(Tracer);
            foreach(connection ; connections)
            {
                if(connection.isReady(sset))
                {
                    connection.handleRequest(hosts);
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
                auto connection = new Connection(acceptedSocket, keepAliveDuration, options[Parameter.MAX_REQUEST]);
                if (isTooManyConnections())
                {
                    log.warning("Rejected connection from ", connection.getHandle().remoteAddress().toString(), " too many connections.");
                    connection.close();
                }
                else
                {
                    connections ~= connection;
                    log.info("Connection from ", connection.getHandle().remoteAddress().toString(), " established, ", connections.length, " active connections");
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
                        listener.listen(options[Parameter.BACKLOG]);
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
            return connections.length >= options[Parameter.MAX_CONNECTION];
        }
}

