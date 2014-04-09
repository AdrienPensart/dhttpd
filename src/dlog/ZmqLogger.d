module dlog.ZmqLogger;

import dlog.LogBackend;
import dlog.Message;
import dlog.MessageFormater;
import dlog.Logger;
import std.conv;
import czmq;

class ZmqLogger : LogBackend
{
    /*
    int zmqMajor, zmqMinor, zmqPatch;
    zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
    string zmqVersion = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
    .log.logging("ZMQ version : ", zmqVersion);
    */
    
    shared static this()
    {
        zctx  = cast(shared(zctx_t *))zctx_new();
        assert(zctx);
    }

    shared static ~this()
    {
        zctx_destroy(cast(zctx_t **)&zctx);
    }

    this(string endpoint, MessageFormater formater = new BinaryMessageFormater)
    {
        super(formater);
        .log.logging("ZMQ Logger endpoint : ", endpoint);
        import std.string : toStringz;
        pusher = zsocket_new (cast(zctx_t *)zctx, ZMQ_PUSH);
        assert(pusher);

        int sndtimeo = 0;
        enum ZMQ_SNDTIMEO = 28;
        zmq_setsockopt(pusher, ZMQ_SNDTIMEO, &sndtimeo, sndtimeo.sizeof);
        auto result = zsocket_connect(pusher, toStringz(endpoint));
        assert(result == 0, to!string(zmq_strerror(zmq_errno())));
    }
    
    override void log(Message m)
    {
        void[] data = formater.format(m);
        send(data);
    }

    private void send(void[] data)
    {
        auto msg = zmsg_new();
        assert(msg);
        auto push = zmsg_addmem(msg, data.ptr, data.length);
        assert(push == 0);
        zmsg_send(&msg, pusher);
    }

    private:

        void * pusher;
        shared static zctx_t * zctx;
}
