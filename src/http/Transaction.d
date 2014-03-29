module http.Transaction;

import loop.EvLoop;

import http.protocol.Request;
import http.protocol.Response;
import http.handler.Handler;

class Transaction
{
	static EvLoop loop;

	string hit;
    Request request;
    Handler handler;
    Response response;

    Response execute()
    {
    	response = handler.execute(request, hit);
    	return response;
    }
}
