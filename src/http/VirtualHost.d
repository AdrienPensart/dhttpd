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
    this(string[] a_hosts, Route[] a_routes)
    {
        this.m_hosts = a_hosts;
        this.m_routes = a_routes;
    }
    
    void addSupportedPorts(ushort[] ports)
    {
        auto bufferHosts = m_hosts;
        foreach(host ; m_hosts)
        {
            foreach(port ; ports)
            {
                if(!inPattern(':', host))
                {
                    auto newHost = host ~ ":" ~ to!string(port);
                    bufferHosts ~= newHost;
                }
            }
        }
        m_hosts = bufferHosts;
    }

    bool matchHostHeader(Request request)
    {
        mixin(Tracer);
        foreach(host ; m_hosts)
        {
            if(request.hasHeader(FieldHost, host))
            {
                return true;
            }
        }
        log.trace("Host not found => fallback");
        return false;
    }

    @property auto hosts()
    {
        return m_hosts;
    }

    Tuple!(Response, Handler) dispatch(Request request)
    {
        foreach(route ; m_routes)
        {
            return route.dispatch(request);
        }
        return typeof(return)(null, null);
    }

    private
    {
        string[] m_hosts;
        Route[] m_routes;
    }
}
