module http.server.RequestHandler;

import http.server.Client;
import http.protocol.Method;
import http.protocol.Request;
import http.protocol.RequestLine;

import dlog.Logger;
import dlog.Tracer;

class RequestHandler
{
    private:

        Client client;
        Request request;

    public:

        this(Client client)
        {
            this.client = client;
            auto lastChunk = client.getLastChunk();
            request = new Request(lastChunk.idup);
        }

        void handle()
        {
            mixin(Tracer);
            if(request.parse())
            {
                log.info("Valid request.");
                auto rl = request.getRequestLine();
                final switch(cast(char[])rl.getMethod())
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
            }
            else
            {
                log.warning("Invalid request.");
            }
        }
}

