import dlog.Logger;

import std.string;
import std.getopt;
import std.socket;
import std.conv;
import std.array;

/*
import zstr;
import zsockopt;
import zframe;
import zsocket;
import zloop;
import zctx;
import zmsg;
import zmq;
*/
import czmq;
import msgpack;

void main(string[] args)
{
    ushort logPort = 9090;
    getopt(args, "logport|lp",   &logPort);

    log.register(new ConsoleLogger);
    log.info("Starting log server on port ", logPort);

    auto zctx = zctx_new();      
    auto loop = zloop_new();
    auto sub = zsocket_new (zctx, ZMQ_PULL);
    auto endpoint = "tcp://127.0.0.1:" ~ to!string(logPort);

    log.info("endpoint : ", endpoint);
    zsocket_bind(sub, toStringz(endpoint));

    while(true)
    {
        try
        {
            auto msg = zmsg_recv(sub);
            if(zctx_interrupted)
            {
                log.info("Interrupted");
                break;
            }
            if(msg is null)
            {
                continue;
            }

            ubyte[] raw;
            auto frame = zmsg_first(msg);
            while(frame !is null)
            {
                ubyte * buffer = cast(ubyte*)zframe_data(frame);
                raw ~= buffer[0..zframe_size(frame)];
                frame = zmsg_next(msg);
            }
            
            Message message = new Message();
            message = raw.unpack!Message();
            log(message.type, message);

            zmsg_destroy(&msg);
        }
        catch(Exception e)
        {
            log.error("Exception : ", e.msg);
        }
    }
    zloop_destroy(&loop);
    zctx_destroy(&zctx);
    log.info("Stopping logging server");
}

/*
//auto logger = new Poller(logPort);
//logger.run();

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
            ubyte[64000] buffer;
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
                Message message = new Message();
                message = buffer[0..datalength].unpack!Message();
                log(message.type, message);
            }
        }
        catch(Exception e)
        {
            log.error(e);
        }
    }
}
*/