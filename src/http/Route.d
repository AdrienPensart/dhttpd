module http.Route;

import std.regex;
import std.typecons;

import http.protocol.Request;
import http.protocol.Response;
import http.handler.Handler;

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

    Tuple!(Response, Handler) dispatch(Request request)
    {
        mixin(Tracer);
        auto m = matchRex(request);
    	if(m)
    	{
    		log.trace("Matched route : ", route);
            log.trace("Hit : ", m.hit);

            auto response = handler.execute(request, m.hit);
    		return typeof(return)(response, handler);
    	}
    	return typeof(return)(null, null);
    }

    private auto matchRex(Request request)
    {
        string uri = request.getUri();
        string path = request.getPath();
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
