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

    Transaction dispatch(Request request)
    {
        mixin(Tracer);
        auto m = matchRex(request);
    	if(m)
    	{
    		log.trace("Matched route : ", route);
            log.trace("Hit : ", m.hit);

            auto transaction = new Transaction;
            transaction.hit = m.hit.idup;
            transaction.request = request;
            transaction.handler = handler;
    		return transaction;
    	}
    	return null;
    }

    private auto matchRex(Request request)
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
