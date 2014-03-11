import dlog.Logger;
import dlog.Message;
import std.getopt;
import std.socket;
import czmq;
import msgpack;

extern(C) int onAcceptHandler(zloop_t * loop, zmq_pollitem_t * item, void * arg)
{
    Poller poller = cast(Poller)arg;
    poller.newClient(item);
    return 0;
}

extern(C) int onMessageHandler(zloop_t * loop, zmq_pollitem_t * item, void * arg)
{
    Poller poller = cast(Poller)arg;
    poller.newMessage(item);
    return 0;
}

class Poller
{
    Socket listener;
    Socket[int] clients;

    zctx_t * context;
    zloop_t * loop;

    this(ushort port)
    {
        context = zctx_new();        
        //zctx_set_linger (context, 10);

        loop = zloop_new();
        //zloop_set_verbose (loop, true);

        listener = new TcpSocket;
        listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
        listener.bind(new InternetAddress(port));
        listener.blocking = false;                    
        listener.listen(100);

        auto pollitem = new zmq_pollitem_t;
        pollitem.events = ZMQ_POLLIN;
        pollitem.fd = listener.handle();
        auto rc = zloop_poller (loop, pollitem, &onAcceptHandler, cast(void*)this);
        enforce(rc == 0);
    }

    ~this()
    {
        zloop_destroy(&loop);
        zctx_destroy(&context);
    }

    void run()
    {
        while(true)
        {
            int zloopResult = zloop_start (loop);
            if(zloopResult == 0)
            {
                log.info("interrupted");
                break;
            }
            else if(zloopResult == -1)
            {
                log.info("interrupted by handler");
                break;
            }
            else
            {
                log.info("interrupted by unknown event");
                break;
            }
        }
    }

    void newClient(zmq_pollitem_t * item)
    {
        mixin(Tracer);
        try
        {
            log.trace("New connection");
            enforce(item.fd == listener.handle());

            auto acceptedSocket = listener.accept();
            acceptedSocket.blocking = false;
            clients[acceptedSocket.handle()] = acceptedSocket;

            auto pollitem = new zmq_pollitem_t;
            pollitem.fd = acceptedSocket.handle();
            pollitem.events = ZMQ_POLLIN;

            auto rc = zloop_poller (loop, pollitem, &onMessageHandler, cast(void*)this);
            enforce(rc == 0);
        }
        catch(Exception e)
        {
            log.error(e);
        }
    }

    void newMessage(zmq_pollitem_t * item)
    {
        mixin(Tracer);
        try
        {
            auto client = clients[item.fd];
            char[64000] buffer;
            auto datalength = client.receive(buffer);
            if (datalength == Socket.ERROR || datalength == 0)
            {
                log.warning("LogServer : Error : ", lastSocketError());
                client.close();
                clients.remove(item.fd);
                zloop_poller_end (loop, item);
            }
            else
            {
                ubyte[] outData = cast(ubyte[])buffer[0..datalength];
                Message message = new Message();
                message = outData.unpack!Message();
                log(message.type, message);
            }
        }
        catch(Exception e)
        {
            log.error(e);
        }
    }
}

void main(string[] args)
{
    mixin(Tracer);

    ushort logPort = 9090;
    getopt(args, "logport|lp",   &logPort);

    log.register(new ConsoleLogger);
    log.info("Starting log server on port ", logPort);
    auto logger = new Poller(logPort);
    logger.run();
    log.info("Stopping logging server");
}
