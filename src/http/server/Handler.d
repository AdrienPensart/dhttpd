module http.server.Handler;

import http.server.Connection;
import http.server.Route;

import http.protocol.Request;
import http.protocol.Response;

interface Handler
{
	Response execute(Request request, string hit);
}

/*
class ErrorHandler : Handler
{
	Response execute(Request request, string hit)
	{
		return true;
	}
}

class WorkerHandler : Handler
{
	Response execute(Request request, string hit)
	{
		return true;
	}
}
*/
