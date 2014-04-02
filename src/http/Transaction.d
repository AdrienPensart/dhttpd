module http.Transaction;

import loop.EvLoop;
import dlog.Logger;
import crunch.Caching;

import http.Config;
import http.Options;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Header;
import http.protocol.Protocol;
import http.handler.Handler;
import http.poller.FilePoller;

class Transaction : ReferenceCounter!(Transaction)
{
	static EvLoop loop;
    static Cache!(uint, Transaction) cache;

	string hit;
    Request request;
    Handler handler;
    Response response;
    FilePoller * poller;

    this(ref Request a_request, Response a_response)
    {
        request = a_request;
        response = a_response;
    }

    this(ref Request a_request, Handler a_handler, string a_hit)
    {
        request = a_request;
        handler = a_handler;
        hit = a_hit;
    }

    static Transaction get(ref Request a_request, Config a_config)
    {
        mixin(Tracer);
        auto transaction = cache.get(a_request.hash, { return compute(a_request, a_config); } );
        if(transaction && transaction.poller && transaction.poller.reload)
        {
            log.info("Executing handler again");
            transaction.execute(transaction.request, a_config);
        }
        return transaction;
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
                // don't cache malformed request
                log.trace("Malformed request => Bad Request");
                auto response = new BadRequestResponse(a_config.options[Parameter.BAD_REQUEST_FILE].toString());
                response.headers[FieldConnection] = "close";
                response.protocol = a_request.protocol;
                transaction = new Transaction (a_request, response);
                break;
        }
        return transaction;
    }

    // invalidate by request hash (timeout ?)
    static void invalidate(Transaction transaction)
    {
        mixin(Tracer);
        uint invalidTransactionHash = transaction.request.hash;
        log.info("Invalidating transaction ", invalidTransactionHash);
        cache.invalidate(invalidTransactionHash);
    }

    private void execute(ref Request a_request, Config a_config)
    {
        mixin(Tracer);
    	if(handler !is null)
        {
            handler.execute(this);
        }

        if(response is null)
        {
            response = new NotFoundResponse(a_config.options[Parameter.NOT_FOUND_FILE].toString());
        }

        if(request.protocol == HTTP_1_0 && a_request.keepalive)
        {
            log.trace("For HTTP 1.0, add header keep alive");
            response.headers[FieldConnection] = KeepAlive;
            response.keepalive = true;
        }
        else
        {
            response.keepalive = a_request.keepalive;
        }
        response.protocol = a_request.protocol;
        response.headers[FieldServer] = a_config.options[Parameter.SERVER_STRING].toString();
    }

    @property bool keepalive()
    {
        return response.keepalive;
    }
}
