module http.server.Server;

import std.socket;

import dlog.Logger;

import interruption.InterruptionException;

import http.server.Config;
import http.server.Client;

class Server
{
    private:
    
        Config config;
        bool interrupted = false;
        Client[] clients;
        SocketSet sset;
        Socket[] listeners;
        const int MAX_CONNECTIONS = 60;
       
    public:
    
        this(Config config)
        {
            sset = new SocketSet(MAX_CONNECTIONS + 1);
            this.config = config;
            listeners = config.aggregateListeners();
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
                log.fatal("No port to listen to...");
                return;
            }

            while(!interrupted)
            {
                try
                {
                    buildSocketSet();
                    selectSockets();        
                    handleReadyClients();
                    cleanClients();
                    pollListeners();
                }
                catch(SocketOSException e)
                {
                    log.error(e);
                }
            }
        }
        
        auto interrupt() nothrow
        {
            interrupted = true;
        }
        
    private:

        void buildSocketSet()
        {
            log.info("Active sockets : ", listeners.length + clients.length, ", max capacity : ", sset.max());
            sset.reset();
            foreach(listener ; listeners)
            {
                sset.add(listener);
            }
            foreach(client ; clients)
            {
                sset.add(client.getHandle());
            }
        }

        void selectSockets()
        {
            mixin(Tracer);
            log.info("Waiting for clients...");
            auto status = Socket.select(sset, null, null);
            if(status == 0)
            {
                log.info("Select timeout.");
            }
            else if (status == -1)
            {
                handleInterruption();
            }
            else
            {
                log.info("Select status : ", status);
            }
        }
    
        void handleInterruption()
        {
            log.info("Select interrupted.");
            throw (interrupted ?
                new InterruptionException : 
                new InterruptionException("Select interrupted for unknow reason"));
        }

        void handleReadyClients()
        {
            mixin(Tracer);
            /*
            for(int i = 0 ; ; i++)
            {
                nextClient: if(i == clients.length)
                {
                    log.info("No more clients left.");
                    break;
                }
                
                Client client = clients[i];
                if(client.isReady(sset))
                {
                    treatClient(client);
                    wipeClientIndexedBy(i);
                    goto nextClient;
                }
            }
            */
            foreach(client ; clients)
            {
                if(client.isReady(sset))
                {
                    client.treat();
                }
            }
        }

        void cleanClients()
        {
            Client[] aliveClients;
            foreach(client ; clients)
            {
                if(client.isAlive())
                {
                    aliveClients ~= client;
                }
            }
            clients = aliveClients;
        }
        /*
        void wipeClientIndexedBy(int i)
        {
            if (i != clients.length - 1)
            {
                clients[i] = clients[clients.length - 1];
            }
            clients = clients[0 .. clients.length - 1];
        }
        */
        void pollListeners()
        {
            mixin(Tracer);
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
            mixin(Tracer);
            try
            {
                auto client = new Client(listener.accept());
                if (isTooManyConnections())
                {
                    log.warning("Rejected connection from ", client.getHandle().remoteAddress().toString(), " too many connections.");
                    client.close();
                }
                else
                {
                    log.info("Connection from ", client.getHandle().remoteAddress().toString(), " established.");
                    clients ~= client;
                }
            }
            catch (Exception e)
            {
                log.error("Error accepting: ", e.toString());
            }
        }

        bool isTooManyConnections()
        {
            return clients.length >= MAX_CONNECTIONS;
        }
}

