module http.server.Client;

import std.socket;

import http.protocol.Parser;
import http.protocol.Request;
import http.protocol.Response;
import http.server.ResponseBuilder;

import dlog.Logger;

class Client
{
    private:
        
        char[] currentChunk;
        Socket handle;
        HttpParser parser;

    public:
    
        this(Socket handle)
        {
            this.handle = handle;
            parser = new HttpParser;
        }
            
        Socket getHandle()
        {
            return handle;
        }
        
        char[] getCurrentChunk()
        {
            return currentChunk;
        }
        
        bool isAlive()
        {
            return handle.isAlive;
        }

        void close()
        {
            if(handle.isAlive)
            {
                handle.shutdown(SocketShutdown.BOTH);
            }
            handle.close();
        }
        
        void treat()
        {
            mixin(Tracer);
            if(readChunk())
            {
                auto currentChunk = getCurrentChunk().idup;
                parser.execute(currentChunk);
                HttpParserStatus status = parser.finish();

                if(status == HttpParserStatus.Finished)
                {
                    auto request = parser.getRequest();
                    auto responseBuilder = new ResponseBuilder(request);

                    if(responseBuilder.build())
                    {
                        Response response = responseBuilder.getResponse();
                        string buffer = response.get();
                        writeChunk(buffer);
                    }
                    close();
                }
                else if(status == HttpParserStatus.HasError)
                {
                    close();
                }

                /*
                request = new Request(currentChunk.idup);
                if(request.parse())
                {
                    log.info("Valid request.");
                }
                else
                {
                    log.warning("Invalid request.");
                }
                
                */                
            }
            else
            {
                close();
            }
        }

        private bool readChunk()
        {
            mixin(Tracer);
            char buffer[1024];
            auto datalength = handle.receive(buffer);
            if (datalength == Socket.ERROR)
            {
                log.error("Connection error.");
                return false;
            }
            else if(datalength == 0)
            {
                log.info("Connection from ", handle.remoteAddress().toString(), " closed.");
                return false;
            }
            currentChunk = buffer[0 .. datalength];
            log.info("Received ", datalength, " bytes from ", handle.remoteAddress().toString(), "\n\"\n", currentChunk, "\n\"");
            return true;
        }
        
        private bool writeChunk(string data)
        {
            mixin(Tracer);
            auto datalength = handle.send(data);
            if (datalength == Socket.ERROR)
            {
                log.error("Connection error.");
                return false;
            }
            else if(datalength == 0)
            {
                log.info("Connection from ", handle.remoteAddress().toString(), " closed.");
                return false;
            }
            log.info("Sent ", datalength, " bytes to ", handle.remoteAddress().toString(), "\n\"\n", data, "\n\"");
            return true;
        }
        
        bool isReady(SocketSet sset)
        {
            return cast(bool) sset.isSet(handle);
        }
}

