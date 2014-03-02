module http.server.Worker;

import http.server.Handler;
import std.string;
import czmq;

class Worker : Handler
{
	zctx_t * zctx;
	void * sender;
	void * receiver;

	this(zctx_t * zctx, string sendAddress, string recvAddress)
	{
		this.zctx = zctx;

		sender = zsocket_new (zctx, ZMQ_PUSH);
		assert(sender);
		zsocket_bind(sender, toStringz(sendAddress));

		receiver = zsocket_new (zctx, ZMQ_PULL);
		assert(receiver);
		zsocket_bind(receiver, toStringz(recvAddress));
	}
	
	~this()
	{
		/*
		zsocket_destroy(zctx, sender);
		zsocket_destroy(zctx, receiver);
		*/
	}

	Response execute(Request request, string hit)
	{
		return null;
	}
}
