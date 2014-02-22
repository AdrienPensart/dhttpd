module http.server.VirtualHost;

import std.conv;

import http.server.Route;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Header;
import dlog.Logger;

class VirtualHost
{        
    this(string[] hosts, Route[] routes)
    {
        this.hosts = hosts;
        this.routes = routes;
    }
    
    void addSupportedPorts(ushort[] ports)
    {
        auto bufferHosts = hosts;
        foreach(host ; hosts)
        {
            foreach(port ; ports)
            {
                auto newHost = host ~ ":" ~ to!string(port);
                log.info("Added new host + port : ", newHost);
                bufferHosts ~= newHost;
            }
        }
        hosts = bufferHosts;
    }

    bool matchHostHeader(Request request)
    {
        mixin(Tracer);
        foreach(host ; hosts)
        {
            if(request.hasHeader(FieldHost, host))
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
