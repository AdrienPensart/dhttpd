module http.handler.Handler;

public import http.server.Transaction;

interface Handler
{
	void execute(Transaction transaction);
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
