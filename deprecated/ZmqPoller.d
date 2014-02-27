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
