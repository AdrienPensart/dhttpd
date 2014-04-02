module http.Route;

import std.regex;

import http.handler.Handler;
import http.protocol.Request;
import http.Transaction;

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

    Transaction dispatch(ref Request request)
    {
        mixin(Tracer);
        auto m = matchRex(request);
    	if(m)
    	{
    		log.trace("Matched route : ", route);
            log.trace("Hit : ", m.hit);
    		return new Transaction(request, handler, m.hit.idup);
    	}
    	return null;
    }

    private auto matchRex(ref Request request)
    {
        auto uri = request.getUri();
        auto path = request.getPath();
        log.trace("ROUTE : ", route, ", URI : ", uri, ", PATH : ", path);
        return match(path, rex);
    }

    private
    {
        Regex!char rex;
    	string route;
    	Handler handler;
    }
}
