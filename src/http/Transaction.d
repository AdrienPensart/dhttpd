module http.Transaction;

import http.protocol.Protocol;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Header;

import http.handler.Handler;
import http.VirtualHost;
import http.Config;
import http.Options;

import crunch.Caching;
import dlog.Logger;

class Transaction : Cacheable!(ubyte[4], Response)
{
	//UUID m_key_request;
    ubyte[4] m_key_request;
    Handler m_handler;
    Request m_request;
	Response m_response;
    Config m_config;

    this(Config a_config, Request a_request)
    {
        import std.uuid;
        import std.digest.crc;

        m_config = a_config;
        m_request = a_request;
        auto m_request_string = m_request.get();
        //m_key_request = sha1UUID(m_request_string);
        m_key_request = crc32Of(m_request_string);
        m_response = null;
    }

    @property auto keepalive()
    {
        return !m_response.hasHeader(FieldConnection, "close");
    }

    @property auto request()
    {
        return m_request;
    }

    @property auto response()
    {
        return m_response;
    }

	override ubyte[4] key()
    {
        return m_key_request;
    }

    override Response get()
    {
        return m_response = super.get();
    }

    override Response value()
    {
        mixin(Tracer);
        m_request.parse();
        final switch(m_request.status())
        {
            case Request.Status.NotFinished:
                log.trace("Request not finished");
                break;
            case Request.Status.Finished:
                log.trace("Request ready : \n\"\n", m_request.get(), "\"");
                

                auto m_tuple = m_config.dispatch(m_request);
                m_response = m_tuple[0];
                m_handler = m_tuple[1];

                if(m_response is null || m_handler is null)
                {
                    log.trace("Host not found and no fallback => Not Found");
                    m_response = new NotFoundResponse(m_config.options[Parameter.NOT_FOUND_FILE].toString());
                }

                if(m_request.keepalive())
                {
                    if(m_request.protocol == HTTP_1_0)
                    {
                        m_response.headers[FieldConnection] = KeepAlive;
                    }
                }
                else
                {
                    m_response.headers[FieldConnection] = "close";
                }
                
                m_response.protocol = m_request.protocol;
                m_response.headers[FieldServer] = m_config.options[Parameter.SERVER_STRING].toString();                
                break;
            case Request.Status.HasError:
                // don't cache malformed request
                log.trace("Malformed request => Bad Request");
                m_response = new BadRequestResponse(m_config.options[Parameter.BAD_REQUEST_FILE].toString());
                m_response.headers[FieldConnection] = "close";
                m_response.protocol = m_request.protocol;
        }
        return m_response;
    }
}
