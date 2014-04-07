module http.Transaction;

import loop.EvLoop;
import dlog.Logger;
import crunch.Caching;

import http.Config;
import http.Options;
import http.Connection;

import http.protocol.Protocol;
import http.handler.Handler;

Cache!(uint, Transaction) httpCache;

class Transaction : ReferenceCounter!(Transaction)
{
    private
    {
    	string m_hit;
        Request m_request;
        Handler m_handler;
        Response m_response;
    }

    this(ref Request a_request, Response a_response)
    {
        mixin(Tracer);
        m_request = a_request;
        m_response = a_response;
    }

    this(ref Request a_request, Handler a_handler, string a_hit)
    {
        mixin(Tracer);
        m_request = a_request;
        m_handler = a_handler;
        m_hit = a_hit;
    }

    bool commit(Connection connection)
    {
        mixin(Tracer);
        return m_response.send(connection);
    }

    static Transaction get(ref Request a_request, Config a_config)
    {
        mixin(Tracer);
        return httpCache.get(a_request.hash, { return compute(a_request, a_config); } );
    }

    private static Transaction compute(ref Request a_request, Config a_config)
    {
        mixin(Tracer);
        Transaction transaction;
        a_request.parse(a_config.options);
        final switch(a_request.status())
        {
            case Request.Status.NotFinished:
                log.trace("Request not finished");
                break;
            case Request.Status.Finished:
                log.trace("Request ready : \n\"\n", a_request.raw[], "\"");
                transaction = a_config.dispatch(a_request);
                log.info("Executing handler for first time");
                transaction.execute(a_request, a_config);
                transaction.response.headers[FieldServer] = a_config.options[Parameter.SERVER_STRING].get!(string);
                break;
            case Request.Status.HasError:
                // cache malformed request in limited manner
                log.trace("Malformed request");
                auto a_response = a_config.options[Parameter.BAD_REQUEST_RESPONSE].get!(Response);
                a_response.headers[FieldConnection] = "close";
                a_response.protocol = a_request.protocol;
                transaction = new Transaction (a_request, a_response);
                break;
        }
        return transaction;
    }

    /*
    // invalidate by request hash (timeout ?)
    static void invalidate(Transaction transaction)
    {
        mixin(Tracer);
        uint invalidTransactionHash = transaction.m_request.hash;
        log.info("Invalidating transaction ", invalidTransactionHash);
        httpCache.invalidate(invalidTransactionHash);
    }
    */
    
    private void execute(ref Request a_request, Config a_config)
    {
        mixin(Tracer);
    	if(m_handler !is null)
        {
            m_handler.execute(this);
        }

        if(m_response is null)
        {
            m_response = a_config.options[Parameter.NOT_FOUND_RESPONSE].get!(Response);
        }

        if(m_request.protocol == HTTP_1_0 && a_request.keepalive)
        {
            log.trace("For HTTP 1.0, add header keep alive");
            m_response.headers[FieldConnection] = KeepAlive;
            m_response.keepalive = true;
        }
        else
        {
            m_response.keepalive = a_request.keepalive;
        }
        m_response.protocol = a_request.protocol;
        m_response.headers[FieldServer] = a_config.options[Parameter.SERVER_STRING].toString();
    }

    @property string hit()
    {
        return m_hit;
    }

    @property bool keepalive()
    {
        return m_response.keepalive;
    }

    @property Request request()
    {
        return m_request;
    }
    
    @property Response response()
    {
        return m_response;
    }

    @property Response response(Response a_response)
    {
        return m_response = a_response;
    }
}
