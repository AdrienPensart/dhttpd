module http.Config;

import std.socket;

import http.protocol.Request;
import http.protocol.Response;
import http.Transaction;
import http.Options;
import http.VirtualHost;

import dlog.Logger;

class Config
{
	private
	{
		InternetAddress[] m_addresses;
	    ushort[] m_ports;
	    string[] m_interfaces;
	    Options m_options;

	    VirtualHost[] m_hosts;
	    // default host
	    VirtualHost m_fallback;
    }
    
    this(Options a_options, string[] a_interfaces, ushort[] a_ports, VirtualHost[] a_hosts, VirtualHost a_fallback=null)
    {
    	m_options = a_options;
    	m_interfaces = a_interfaces;
        m_ports = a_ports;
        m_hosts = a_hosts;
        m_fallback = a_fallback;

        foreach(host; m_hosts)
        {
            host.addSupportedPorts(m_ports);
        }

        foreach(host; m_hosts)
        {
            log.info("Host : ", host.hosts);
        }

        foreach(netInterface ; m_interfaces)
        {
            foreach(port ; m_ports)
            {
            	m_addresses ~= new InternetAddress(netInterface, port);
            }
        }
    }

    @property auto options()
    {
    	return m_options;
    }

    @property auto addresses()
    {
    	return m_addresses;
    }

    Transaction dispatch(ref Request request)
    {
        mixin(Tracer);
        foreach(host ; m_hosts)
        {
            if(host.matchHostHeader(request))
            {
                log.trace("Host header matched");
                return host.dispatch(request);
            }
        }

        Transaction transaction = null;
        // not host found, fallback on default host
        if(m_fallback)
        {
            log.trace("Host not found => fallback");
            transaction = m_fallback.dispatch(request);
        }

        if(!transaction)
        {
            log.trace("Host not found and no fallback => Not Found");
            transaction = new Transaction(request, new NotFoundResponse(m_options[Parameter.NOT_FOUND_FILE].toString()));
        }
        return transaction;
    }
}
