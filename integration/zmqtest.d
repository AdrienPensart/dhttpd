import czmq;
import std.stdio;
import std.string : format;

void main()
{
	int zmqMajor, zmqMinor, zmqPatch;
    zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
    string zmqVersion = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
    writeln("ZMQ version : ", zmqVersion);

	zctx_t * zctx  = zctx_new();
	zloop_t * zloop = zloop_new();
	void * sender;
	void * receiver;

	sender = zsocket_new (zctx, ZMQ_PUSH);
	assert(sender);
	zsocket_bind(sender, "");
	
	receiver = zsocket_new (zctx, ZMQ_PULL);
	assert(receiver);
	zsocket_bind(receiver, "");
}
