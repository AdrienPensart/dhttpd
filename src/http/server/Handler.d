module http.server.Handler;

import http.server.Route;

public import http.protocol.Request;
public import http.protocol.Response;

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


*/
