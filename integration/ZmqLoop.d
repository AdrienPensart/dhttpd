import czmq;
import zsys;

class ZmqLoop : Loop
{
    this()
    {
        /*
        zsys_handler_reset ();
        zsys_handler_set (null);
        */
        version(assert)
        {
            int zmqMajor, zmqMinor, zmqPatch;
            zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
            string zmqVersion = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
            writeln("ZMQ version : ", zmqVersion);
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
        
    }

    zctx_t * zctx;
    zloop_t * zloop;
}