module http.server.Host;

import http.server.Route;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Header;
import dlog.Logger;

class Host
{        
    this(string[] hosts, Route[] routes)
    {
        this.hosts = hosts;
        this.routes = routes;
    }
    
    bool matchHostHeader(Request request)
    {
        foreach(host ; hosts)
        {
            if(request.hasHeader(Header.Host, host))
            {
                return true;
            }
        }
        return false;
    }

    Response dispatch(Request request)
    {
        foreach(route ; routes)
		{
            return route.dispatch(request);
		}
        return null;
    }

private:

    string[] hosts;
    Route[] routes;
}
