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

import http.server.Config;
import http.server.Cache;
import http.server.VirtualHost;

import dlog.Logger;

class Connection
{
private:
        HttpCache cache;
        bool keepalive;
        Config config;
        Address address;
        Socket handle;
        Duration keepAliveDuration;
        TickDuration keepAliveTimer;
        uint maxRequest;
        uint processedRequest;
        Request currentRequest;
public:
    this(Socket handle, Config config)
    {
        keepalive = true;
        this.handle = handle;
        this.address = handle.remoteAddress();
        this.config = config;
        this.cache = config[Parameter.HTTP_CACHE].get!(HttpCache);
        setKeepAliveDuration(config[Parameter.KEEP_ALIVE_TIMEOUT].get!(Duration));
        setMaxRequest(config[Parameter.MAX_REQUEST].get!(int));
        refreshKeepAlive();
    }
    
    void handleRequest(VirtualHost[] hosts, VirtualHost defaultHost)
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

        // search in cache, build UUID of request
        UUID requestId = currentRequest.getId();
        if(cache.exists(requestId))
        {
            log.trace("HTTP cache hit on ", requestId);
            Transaction transaction = cache.get(requestId);
            send(transaction.response);
            currentRequest = null;
        }
        else
        {                                                                  
            log.trace("HTTP cache DIT NOT hit, parsing request");
            currentRequest.parse();
            Request.Status status = currentRequest.getStatus();
            if(status == Request.Status.Finished)
            {
                Response currentResponse = null;
                //log.trace("Request ready : \n\"\n",currentRequest.get(), "\"");
                foreach(host ; hosts)
                {
                    if(host.matchHostHeader(currentRequest))
                    {
                        currentResponse = host.dispatch(currentRequest);
                        break;
                    }
                }

                if(currentResponse is null)
                {
                    // not host found, fallback on default host
                    if(defaultHost !is null)
                    {
                        log.warning("Host not found => Fallback on default");
                        currentResponse = defaultHost.dispatch(currentRequest);
                    }
                    else
                    {
                        log.warning("Host not found and no default host => Not Found");
                        currentResponse = new NotFoundResponse(config[Parameter.NOT_FOUND_FILE].toString());
                    }
                }

                if(currentResponse is null)
                {
                    currentResponse = new NotFoundResponse(config[Parameter.NOT_FOUND_FILE].toString());
                }

                log.trace("Saving transaction in cache");
                if(!currentRequest.keepalive())
                {
                    log.trace("Disable keep-alive");
                    currentResponse.headers[FieldConnection] = "close";
                }
                
                currentResponse.protocol = currentRequest.protocol;
                currentResponse.headers[FieldServer] = config[Parameter.SERVER_STRING].toString();

                // put request and response in cache
                Transaction transaction = new Transaction();
                transaction.request = currentRequest;
                transaction.response = currentResponse;

                cache.add(requestId, transaction);

                log.info("Request cached : \n", transaction.request.get());
                log.info("Response cached : \n", transaction.response.get());

                send(transaction.response);
                currentRequest = null;
            }
            else if(status == Request.Status.HasError)
            {
                log.warning("Malformed request => Bad Request");
                Response badRequestResponse = new BadRequestResponse(config[Parameter.BAD_REQUEST_FILE].toString());
                badRequestResponse.protocol = currentRequest.protocol;
                send(badRequestResponse);
                currentRequest = null;
            }
            else if(status == Request.Status.NotFinished)
            {
                log.trace("Request not finished");
            }
        }
    }

    private bool send(Response response)
    {
        mixin(Tracer);
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
        log.trace("Closing ", address);
        handle.close();
    }

    void shutdown()
    {
        log.trace("Shutting down ", address);
        if(handle.isAlive)
        {
            handle.shutdown(SocketShutdown.BOTH);
        }
    }

    private void refreshKeepAlive()
    {
        keepAliveTimer = TickDuration.currSystemTick();
    }

    private char[] readChunk()
    {
        static char buffer[1024];
        auto datalength = handle.receive(buffer);
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

    private bool writeChunk(ref string data)
    {
        auto datalength = handle.send(data);
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
        
    bool isAlive()
    {
        return handle.isAlive;
    }

    bool tooMuchRequests()
    {
        log.trace("Processed requests : ", processedRequest);
        log.trace("Max requests : ", maxRequest);
        log.trace("Too much request : ", processedRequest > maxRequest);
        return processedRequest > maxRequest;
    }

    bool isValid()
    {
        log.trace("keep alive ? : ", keepalive);
        return keepalive && !isTimeout() && !tooMuchRequests() && handle.handle != -1 && isAlive();
    }

    bool isTimeout()
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
