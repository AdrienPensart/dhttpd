module http.server.Route;

import std.regex;

import http.protocol.Request;
import http.protocol.Response;
import http.server.Handler;

import dlog.Logger;
import crunch.AliveReference;

class Route : AliveReference!Route
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
        mixin(Tracer);
        auto m = matchRex(request);
    	if(m)
    	{
    		log.trace("Matched route : ", route);
            log.trace("Hit : ", m.hit);
    		return handler.execute(request, m.hit);
    	}
    	return null;
    }

    private auto matchRex(Request request)
    {
        string uri = request.getUri();
        string path = request.getPath();
        log.trace("ROUTE : ", route, ", URI : ", uri, ", PATH : ", path);
        return match(path, rex);
    }

    private:

        Regex!char rex;
    	string route;
    	Handler handler;
}
