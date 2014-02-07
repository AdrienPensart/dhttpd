import std.socket;
import std.stdio;

import Log;
import Analyzer;

class InterruptException : Exception
{
    this(string msg="User interruption", string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

// IP version level dispatcher / Interface dispatcher
class InterfaceListener
{
    public:

        this(string[] identifiers, PortListener[] ports)
        {
            this.identifiers = identifiers;
            this.ports = ports;
        }

        auto getPorts()
        {
            return ports;
        }

    private:

       string[] identifiers;
       PortListener[] ports;
}

// Port level
class PortListener
{
    public:
        
        static int defaultBacklog = 10;

        this(ushort[] ports, WebsiteListener[] websites)
        {
            mixin(Tracer);
            this.websites = websites;

            foreach(port ; ports)
            {
                try
                {
                    auto listener = new TcpSocket;
                    listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                    listener.bind(new InternetAddress(port));
                    listener.listen(defaultBacklog);
                    listeners ~= listener;
                    lout.info("Listening on port ", port);
                }
                catch(SocketOSException e)
                {
                    lout.error("Can't bind to port. ", e.msg);
                }
            }
        }

        auto getListeners()
        {
            return listeners;
        }

        auto getWebsites()
        {
            return websites;
        }

    private:

        WebsiteListener[] websites;
        Socket[] listeners;
}

// Host level
class WebsiteListener
{
    public:
        
        this(string[] hosts, LocationListener[] locations)
        {
            this.hosts = hosts;
            this.locations = locations;
        }
         
        string[] hosts;
        LocationListener[] locations;
}

// Route level
class LocationListener
{
    public:
    
        this(string publicDir, string indexFilename)
        {
            this.publicDir = publicDir;
            this.indexFilename = indexFilename;
        }
        
    private:

        string publicDir;
        string indexFilename;
}

class Webserver
{
    public:

        this()
        {
            sset = new SocketSet(MAX_CONNECTIONS + 1);
            auto root = new LocationListener("/var/www", "index.html");
            auto test = new WebsiteListener([""],[root]);
            auto ports = new PortListener([8080, 8081], [test]);
            auto interfaces = new InterfaceListener(["0.0.0.0"], [ports]);
             
            foreach(portListener ; interfaces.getPorts())
            {
                foreach(listener ; portListener.getListeners())
                {
                    lout.info("Adding listener.");
                    listeners ~= listener;
                }
            }
        }

        void interrupt() nothrow
        {
            interrupted = true;
        }

        void run()
        {
            mixin(Tracer);
            
            if(!listeners.length)
            {
                lout.fatal("No port to listen too...");
                return;
            }

            for (;!interrupted;sset.reset())
            {
                try
                {
                    selectSockets();        
                    pollClients();         
                    pollListeners();

                }
                catch(SocketOSException e)
                {
                    lout.error(e);
                }
            }
        }
    
    private:

        void selectSockets()
        {
            auto allSockets = clients ~ listeners; 
            lout.info("Sockets actifs : ", allSockets.length, " pour une capacite maximale de ", sset.max());
            foreach(socket ; allSockets)
            {
                sset.add(socket);
            }
                    
            lout.info("Waiting for clients...");
            auto status = Socket.select(sset, null, null);
            if(status == 0)
            {
                lout.info("Select timeout.");
            }
            else if (status == -1)
            {
                lout.info("Select interrupted.");
                if(interrupted)
                {
                    throw new InterruptException;
                }
                else
                {
                    throw new InterruptException("Select interrupted for unknow reason");
                }
            }
            else
            {
                lout.info("Select status : ", status);
            }
        }

        void pollClients()
        {
            for(int i = 0 ; ; i++)
            {
                again: if(i == clients.length)
                {
                    lout.info("No more clients left.");
                    break;
                }
                        
                if(sset.isSet(clients[i]))
                {
                    char buffer[1024];
                    auto datalength = clients[i].receive(buffer);
                    if (datalength == Socket.ERROR)
                    {
                        lout.error("Connection error.");
                    }
                    else if(datalength == 0)
                    {
                        lout.info("Connection from ", clients[i].remoteAddress().toString(), " closed.");
                    }
                    else
                    {
                        auto request = buffer[0 .. datalength];
                        lout.info("Received ", datalength, " bytes from ", clients[i].remoteAddress().toString(), ": \"", request, "\"");
                        auto hr = new Http.Request;
                        if(hr.parse(request.idup))
                        {
                            lout.info("Valid request.");
                        } 
                        else
                        {
                            lout.warning("Invalid request.");
                        }
                   }
                   clients[i].shutdown(SocketShutdown.BOTH);
                   clients[i].close();
                   if (i != clients.length - 1)
                   {
                       clients[i] = clients[clients.length - 1];
                   }
                   clients = clients[0 .. clients.length - 1];
                   goto again;
               }
            }
        }

        void pollListeners()
        {
            foreach(listener ; listeners)
            {
                if(sset.isSet(listener))
                {
                    acceptNewClient(listener);
                }
            }
        }

        void acceptNewClient(Socket listener)
        {
            Socket client;
            try
            {
                client = listener.accept();
                if (clients.length >= MAX_CONNECTIONS)
                {
                    lout.warning("Rejected connection from ", client.remoteAddress().toString(), " too many connections.");
                    client.shutdown(SocketShutdown.BOTH);
                    client.close();
                }
                else
                {
                    lout.info("Connection from ", client.remoteAddress().toString(), " established.");
                    clients ~= client;
                }
            }
            catch (Exception e)
            {
                lout.error("Error accepting: ", e.toString());
                if (client)
                {
                    client.close();
                }
            }
        }

        bool interrupted = false;
        Socket[] clients;
        SocketSet sset;
        Socket[] listeners;
        const int MAX_CONNECTIONS = 60;
}

