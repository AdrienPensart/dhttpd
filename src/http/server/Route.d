module http.server.Route;

import std.regex;

import http.handler.Handler;
import http.protocol.Request;
import http.server.Transaction;

import dlog.Logger;

class Route
{
    this(string a_route, Handler a_handler)
    {
    	m_route = a_route;
    	m_handler = a_handler;

        m_rex = regex(m_route);
    }

    @property auto handler()
    {
        return m_handler;
    }

    Transaction dispatch(ref Request request)
    {
        mixin(Tracer);
        auto m = matchRex(request);
    	if(m)
    	{
    		log.trace("Matched route : ", m_route);
            log.trace("Hit : ", m.hit);
    		return new Transaction(request, m_handler, m.hit.idup);
    	}
    	return null;
    }

    private auto matchRex(ref Request request)
    {
        auto uri = request.getUri();
        auto path = request.getPath();
        log.trace("Match data : ", m_route, ", URI : ", uri, ", PATH : ", path);
        return matchFirst(path, m_rex);
    }

    private
    {
        Regex!char m_rex;
    	string m_route;
    	Handler m_handler;
    }
}
