module http.handler.Worker;

import http.handler.Handler;
import http.poller.ZmqPoller;

import std.string;

import zmq;
import zctx;
import zsocket;

class Worker : Handler
{
	ZmqPoller sender2;
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
		
		/*
		sender = zsocket_new(zctx, ZMQ_PUB);
		assert(sender);
		zsocket_bind(sender, toStringz(sendAddress));

		receiver = zsocket_new (zctx, ZMQ_PULL);
		assert(receiver);
		zsocket_bind(receiver, toStringz(recvAddress));
		*/
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
