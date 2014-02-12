module http.server.Connection;

import std.socket;
import std.array;
import core.thread;
import core.time;

import http.protocol.Request;
import http.protocol.Response;
import http.server.ResponseBuilder;

import dlog.Logger;

class Connection
{
    private:
        
        char[] currentChunk;
        Socket handle;
        Duration keepAliveDuration;
        TickDuration keepAliveTimer;
        uint maxRequest;
        uint processedRequest;
        Request[] requestQueue;
        Request currentRequest;

    public:
    
        this(Socket handle, Duration keepAliveDuration, uint maxRequest)
        {
            this.handle = handle;
            setKeepAliveDuration(keepAliveDuration);
            setMaxRequest(maxRequest);
            refreshKeepAlive();
        }
        
        Socket getHandle()
        {
            return handle;
        }
        
        void setMaxRequest(uint maxRequest)
        {
            this.maxRequest = maxRequest;
        }

        void setKeepAliveDuration(Duration keepAliveDuration)
        {
            this.keepAliveDuration = keepAliveDuration;
        }

        void close()
        {
            if(handle.isAlive)
            {
                handle.shutdown(SocketShutdown.BOTH);
            }
            log.info(handle.remoteAddress().toString(), " disconnected");
            handle.close();
        }
        
        Request getNextRequest()
        {
            if(isRequestPending())
            {
                Request next = requestQueue.front();
                requestQueue.popFront();
                return next;
            }
            return null;
        }

        bool isRequestPending()
        {
            return !requestQueue.empty;
        }

        void handleRequest()
        {
            mixin(Tracer);
            if(readChunk())
            {
                if(currentRequest is null)
                {
                    currentRequest = new Request();
                }

                auto currentChunk = currentChunk.idup;
                currentRequest.feed(currentChunk);
                Request.Status status = currentRequest.getStatus();
                final switch(status)
                {
                    case Request.Status.NotFinished:
                        break;
                    case Request.Status.Finished:
                        processedRequest += 1;
                        requestQueue ~= currentRequest;
                        currentRequest = new Request();
                        break;
                    case Request.Status.HasError:
                        log.warning("Malformed request.");
                        requestQueue ~= currentRequest;
                        currentRequest = new Request();
                        break;
                }
            }
        }

        void sendResponse(Response response)
        {
            string buffer = response.get();
            writeChunk(buffer);
        }

        private void refreshKeepAlive()
        {
            keepAliveTimer = TickDuration.currSystemTick();
        }

        private bool readChunk()
        {
            mixin(Tracer);
            static char buffer[1024];
            auto datalength = handle.receive(buffer);
            if (datalength == Socket.ERROR)
            {
                log.error("Connection error.");
                close();
                return false;
            }
            else if(datalength == 0)
            {
                log.info("Connection from ", handle.remoteAddress().toString(), " closed.");
                close();
                return false;
            }
            currentChunk = buffer[0 .. datalength];
            refreshKeepAlive();
            log.info("Received ", datalength, " bytes from ", handle.remoteAddress().toString(), "\n\"\n", currentChunk, "\"");
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
        
        bool isAlive()
        {
            return handle.isAlive;
        }

        bool tooMuchRequests()
        {
            return processedRequest > maxRequest;
        }

        bool isReady(SocketSet sset)
        {
            return cast(bool) sset.isSet(handle);
        }

        bool isValid()
        {
            return !isTimeout() && !tooMuchRequests() && isAlive();
        }

        bool isTimeout()
        {
            TickDuration currentDuration =  TickDuration.currSystemTick() - keepAliveTimer;
            Duration duration = keepAliveDuration - currentDuration;
            return duration.isNegative();
        }
}

