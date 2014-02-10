module http.server.ResponseBuilder;
import std.conv;

import http.server.Client;
import http.protocol.Status;
import http.protocol.Method;
import http.protocol.Request;
import http.protocol.Response;

import dlog.Logger;

class ResponseBuilder
{
    Request request;
    Response response;

    this(Request request)
    {
        this.request = request;
        response = new Response;
    }
    
    Response getResponse()
    {
        return response;
    }

    bool build()
    {        
        response.protocolVersion = request.getVersion();
        response.status = Status.Ok;
        response.message = "<html>Test</html>\n";
        
        response.headers["Connection"] = "close";
        response.headers["Content-Type"] = "text/html";
        response.headers["Content-Length"] = to!string(response.message.length);
        switch(request.getMethod())
        {
            case Method.GET:
                break;
            case Method.DELETE:
                break;
            case Method.HEAD:
                break;
            case Method.POST:
                break;
            case Method.PUT:
                break;
            case Method.CONNECT:
                break;
            case Method.OPTIONS:
                break;
            case Method.TRACE:
                break;
            case Method.COPY:
                break;
            case Method.LOCK:
                break;
            case Method.MKCOL:
                break;
            case Method.MOVE:
                break;
            case Method.PROPFIND:
                break;
            case Method.PROPPATCH:
                break;
            case Method.SEARCH:
                break;
            case Method.UNLOCK:
                break;
            case Method.REPORT:
                break;
            case Method.MKACTIVITY:
                break;
            case Method.CHECKOUT:
                break;
            case Method.MERGE:
                break;
            case Method.MSEARCH:
                break;
            case Method.NOTIFY:
                break;
            case Method.SUBSCRIBE:
                break;
            case Method.UNSUBSCRIBE:
                break;
            case Method.PATCH:
                break;
            case Method.PURGE:
                break;
            default:
                log.info("HTTP Method not supported : ", request.getMethod());
                return false;
        }
        return true;
    }
}

