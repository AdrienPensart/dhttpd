module http.server.Route;

import std.regex;

import http.protocol.Request;
import http.protocol.Response;
import http.server.Handler;

import dlog.Logger;

class Route
{
    this(string route, Handler handler)
    {
    	this.route = route;
    	this.handler = handler;
        rex = regex(route);
    }

    auto getHandler()
    {
        return handler;
    }

    Response dispatch(Request request)
    {
        auto m = matchRex(request);
    	if(m)
    	{
    		log.info("Matched route : ", route);
            log.info("Hit : ", m.hit);
    		return handler.execute(request, m.hit);
    	}
    	return null;
    }

    private auto matchRex(Request request)
    {
        string uri = request.getUri();
        string path = request.getPath();
        log.info("ROUTE : ", route, ", URI : ", uri, ", PATH : ", path);
        return match(path, rex);
    }

    private:

        Regex!char rex;
    	string route;
    	Handler handler;
}
