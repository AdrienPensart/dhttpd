module http.server.Connection;

import std.socket;
import std.array;
import std.file;
import core.time;

import http.protocol.Protocol;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Status;
import http.protocol.Header;

import http.server.Transaction;
import http.server.Config;
import http.server.VirtualHost;

import dlog.Logger;
import crunch.Caching;
import crunch.AliveReference;

class Connection : AliveReference!Connection
{
    private
    {
        bool keepalive;
        Config config;
        Address address;
        Socket socket;
        Duration keepAliveDuration;
        TickDuration keepAliveTimer;
        uint maxRequest;
        uint processedRequest;
        Request currentRequest;
    }

    public
    {
        this(Socket socket, Config config)
        {
            keepalive = true;
            this.socket = socket;
            this.address = socket.remoteAddress();
            this.config = config;
            setKeepAliveDuration(config[Parameter.KEEP_ALIVE_TIMEOUT].get!(Duration));
            setMaxRequest(config[Parameter.MAX_REQUEST].get!(int));
            refreshKeepAlive();
        }

        void handleRequest(VirtualHostConfig virtualHostConfig)
        {
            mixin(Tracer);
            auto buffer = readChunk();
            if(!buffer.length)
            {
                return;
            }
            
            if(currentRequest is null)
            {
                currentRequest = new Request();
            }
            currentRequest.feed(buffer);

            scope Transaction transaction = new Transaction(virtualHostConfig);
            currentRequest.parse();
            final switch(currentRequest.status())
            {
                case Request.Status.NotFinished:
                    return;
                case Request.Status.Finished:
                    log.trace("Request ready : \n\"\n",currentRequest.get(), "\"");
                    transaction.response = virtualHostConfig.dispatch(currentRequest);
                    if(transaction.response is null)
                    {
                        log.trace("Host not found and no fallback => Not Found");
                        transaction.response = new NotFoundResponse(config[Parameter.NOT_FOUND_FILE].toString());
                    }

                    if(!currentRequest.keepalive())
                    {
                        log.trace("Disable keep-alive");
                        transaction.response.headers[FieldConnection] = "close";
                    }
                    
                    transaction.response.protocol = currentRequest.protocol;
                    transaction.response.headers[FieldServer] = config[Parameter.SERVER_STRING].toString();

                    // put request and response in cache
                    transaction.request = currentRequest;
                    /*
                    cache.add(requestId, transaction);
                    log.info("Request cached : \n", transaction.request.get());
                    log.info("Response cached : \n", transaction.response.get());
                    */
                    break;
                case Request.Status.HasError:
                    // don't cache malformed request
                    log.warning("Malformed request => Bad Request");
                    transaction.response = new BadRequestResponse(config[Parameter.BAD_REQUEST_FILE].toString());
                    transaction.response.protocol = currentRequest.protocol;
            }
            
            send(transaction);
            currentRequest = null;
        }

        auto getHandle()
        {
            return this.socket.handle;
        }

        auto getSocket()
        {
            return this.socket;
        }
            
        auto setMaxRequest(uint maxRequest)
        {
            this.maxRequest = maxRequest;
        }

        auto setKeepAliveDuration(Duration keepAliveDuration)
        {
            this.keepAliveDuration = keepAliveDuration;
        }

        void close()
        {
            mixin(Tracer);
            log.trace("Closing ", address);
            this.socket.close();
        }

        void shutdown()
        {
            mixin(Tracer);
            log.trace("Shutting down ", address);
            if(this.socket.isAlive)
            {
                this.socket.shutdown(SocketShutdown.BOTH);
            }
        }
            
        auto isAlive()
        {
            return socket.isAlive;
        }

        auto tooMuchRequests()
        {
            log.trace("Processed requests : ", processedRequest);
            log.trace("Max requests : ", maxRequest);
            log.trace("Too much request : ", processedRequest > maxRequest);
            return processedRequest > maxRequest;
        }

        auto isValid()
        {
            log.trace("keep alive ? : ", keepalive);
            return keepalive && !isTimeout() && !tooMuchRequests() && socket.handle != -1 && isAlive();
        }

        auto isTimeout()
        {
            TickDuration currentDuration = TickDuration.currSystemTick() - keepAliveTimer;
            Duration duration = keepAliveDuration - currentDuration;
            log.trace("Duration : ", duration);
            log.trace("Connection timeout ? ", duration.isNegative());
            return duration.isNegative();
        }

        auto getAddress()
        {
            return address;
        }
    }

    private
    {
        bool send(Transaction transaction)
        {
            mixin(Tracer);
            auto response = transaction.response;
            //log.trace("Sending response : \n\"\n", response.get(), "\"");
            if(response.keepalive())
            {
                processedRequest++;
                refreshKeepAlive();
            }
            else
            {
                keepalive = false;
            }
            return writeChunk(response.get());
        }

        void refreshKeepAlive()
        {
            keepAliveTimer = TickDuration.currSystemTick();
        }

        char[] readChunk()
        {
            static char buffer[1024];
            auto datalength = socket.receive(buffer);
            if (datalength == Socket.ERROR)
            {
                log.trace("receive socket error");
                keepalive = false;
                return [];
            }
            else if(datalength == 0)
            {
                log.trace("no data on socket, disconnected");
                keepalive = false;
                return [];
            }
            return buffer[0..datalength];
        }

        bool writeChunk(ref string data)
        {
            auto datalength = socket.send(data);
            if (datalength == Socket.ERROR)
            {
                log.trace("Connection error.");
                return false;
            }
            else if(datalength == 0)
            {
                log.trace("Connection from ", address, " closed.");
                return false;
            }
            return true;
        }
    }
}
