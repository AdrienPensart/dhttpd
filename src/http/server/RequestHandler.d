module http.server.RequestHandler;

import http.server.Client;
import http.server.ResponseBuilder;

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

        Request handle()
        {
            mixin(Tracer);
            if(request.parse())
            {
                log.info("Valid request.");
            }
            else
            {
                log.warning("Invalid request.");
            }
            return request;
        }
}

