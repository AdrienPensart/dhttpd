module http.server.VirtualHost;

import std.conv;

import http.server.Route;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Header;
import dlog.Logger;

class VirtualHostConfig
{
    this(VirtualHost[] a_hosts, VirtualHost a_fallback=null)
    {
        hosts = a_hosts;
        fallback = a_fallback;
    }

    Response dispatch(Request request)
    {
        foreach(host ; hosts)
        {
            if(host.matchHostHeader(request))
            {
                return host.dispatch(request);
            }
        }
        // not host found, fallback on default host
        if(fallback !is null)
        {
            log.warning("Host not found => fallback");
            return fallback.dispatch(request);
        }
        return null;
    }

    VirtualHost[] hosts;
    // default host
    VirtualHost fallback;
}

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
