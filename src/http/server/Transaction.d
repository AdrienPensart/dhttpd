module http.server.Transaction;

import http.protocol.Request;
import http.protocol.Response;
import http.server.VirtualHost;

import crunch.Caching;
import std.uuid;

import dlog.Logger;

// AliveReference!Transaction, 
class Transaction : Cacheable!(Request, Response)
{
	Request m_request;
	Response m_response;
    VirtualHostConfig m_vhc;

    this(VirtualHostConfig a_vhc)
    {
        m_vhc = a_vhc;
    }

    @property auto request()
    {
        return m_request;
    }

    @property auto request(Request a_request)
    {
        return m_request = a_request;
    }

    @property auto response()
    {
        return m_response;
    }

    @property auto response(Response a_response)
    {
        return m_response = a_response;
    }

	override Request key()
    {
        return request;
    }

    override Response value()
    {
        return response;
    }
}
