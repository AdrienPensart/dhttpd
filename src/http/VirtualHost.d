module http.VirtualHost;

import std.typecons;
import std.string;
import std.conv;

import http.Route;
import http.handler.Handler;
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
                if(!inPattern(':', host))
                {
                    auto newHost = host ~ ":" ~ to!string(port);
                    bufferHosts ~= newHost;
                    log.info("Added new host + port : ", newHost);
                }
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

    Tuple!(Response, Handler) dispatch(Request request)
    {
        foreach(route ; routes)
        {
            return route.dispatch(request);
        }
        return typeof(return)(null, null);
    }

    private
    {
        string[] hosts;
        Route[] routes;
    }
}
