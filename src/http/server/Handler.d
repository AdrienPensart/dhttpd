module http.server.Handler;

import http.server.Connection;

interface Handler
{
	void execute(Connection);
}

class ErrorHandler : Handler
{
	void execute(Connection connection)
	{

	}
}

class WorkerHandler : Handler
{
	void execute(Connection connection)
	{

	}
}
