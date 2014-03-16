module ZmqLoop;

import dlog.Logger;
import Loop;
import czmq;

class ZmqLoop : Loop
{
    this()
    {
        //import zsys;
        //zsys_handler_reset ();
        //zsys_handler_set (null);
        
        version(assert)
        {
            import std.string : format;
            int zmqMajor, zmqMinor, zmqPatch;
            zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
            string zmqVersion = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
            log.info("ZMQ version : ", zmqVersion);
        }

        zctx = zctx_new();
        assert(zctx);
        //zctx_set_linger (context, 10);

        zloop = zloop_new();
        assert(zloop);
    }

    ~this()
    {
        zctx_destroy(&zctx);
    }

    auto context()
    {
        return zctx;
    }

    override void run()
    {
        lastCode = zloop_start(zloop);
    }

    int lastCode;
    zctx_t * zctx;
    zloop_t * zloop;
}