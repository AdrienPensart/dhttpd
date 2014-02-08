module http.server.ResponseBuilder;

import http.server.Client;
import http.protocol.Status;
import http.protocol.Method;
import http.protocol.Request;
import http.protocol.Response;

import dlog.Logger;
import dlog.Tracer;

class ResponseBuilder
{
    Request request;
    
    this(Request request)
    {
        this.request = request;
    }
    
    Response build()
    {
        auto rl = request.getRequestLine();
        Response response = new Response;
        
        response.protocolVersion = request.rl.protocolVersion;
        response.status = Status.Ok;
        response.message = "<html>Test</html>\n";
        
        response.headers["Connection"] = "close";
        response.headers["Content-Type"] = "text/html";
        
        final switch(rl.getMethod())
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
        }
        return response;      
    }
}

