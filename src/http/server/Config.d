module http.server.Config;

import std.socket;
import http.server.VirtualHost;
import dlog.Logger;

public import http.server.Options;

class Config
{
	private
	{
		InternetAddress[] m_addresses;
	    ushort[] m_ports;
	    string[] m_interfaces;
	    Options * m_options;

	    VirtualHost[] m_hosts;
	    // default host
	    VirtualHost m_fallback;
    }
    
    this(Options * a_options, string[] a_interfaces, ushort[] a_ports, VirtualHost[] a_hosts, VirtualHost a_fallback=null)
    {
        mixin(Tracer);
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

    @property ref Options options()
    {
    	return *m_options;
    }

    @property InternetAddress[] addresses()
    {
    	return m_addresses;
    }

    @property VirtualHost fallback()
    {
        return m_fallback;
    }

    @property VirtualHost[] hosts()
    {
        return m_hosts;
    }
}
