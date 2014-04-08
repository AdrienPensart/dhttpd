module http.server.VirtualHost;

import std.string;
import std.conv;

import http.server.Route;
import http.server.Transaction;
import http.protocol.Request;
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

    bool matchHostHeader(ref Request request)
    {
        mixin(Tracer);
        foreach(host ; m_hosts)
        {
            if(request.hasHeader(FieldHost, host))
            {
                return true;
            }
        }
        return false;
    }

    @property auto hosts()
    {
        return m_hosts;
    }

    Transaction dispatch(ref Request request)
    {
        mixin(Tracer);
        Transaction transaction;
        foreach(route ; m_routes)
        {
            transaction = route.dispatch(request);
            if(transaction)
            {
                break;
            }
        }
        return transaction;
    }

    private
    {
        string[] m_hosts;
        Route[] m_routes;
    }
}
