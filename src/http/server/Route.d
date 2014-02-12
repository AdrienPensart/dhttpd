module http.server.Route;

import http.server.Handler;

class Route
{    
    this(string path, Handler[] handlers)
    {
    	this.path = path;
    	this.handlers = handlers;
    }

private:

	string path;
	Handler[] handlers;
}
