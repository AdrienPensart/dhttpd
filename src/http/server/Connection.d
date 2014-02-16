module http.server.Connection;

import std.socket;
import std.array;
import std.file;
import core.thread;
import core.time;

import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Status;
import http.protocol.Header;

import http.server.Config;
import http.server.Host;

import dlog.Logger;

class Connection
{
    this(Socket handle, Duration keepAliveDuration, uint maxRequest)
    {
        this.handle = handle;
        this.address = handle.remoteAddress();
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
        handle.close();
        log.info("Connection ", address, " closed.");
    }

    void handleRequest(Host[] hosts)
    {
        mixin(Tracer);
        if(readChunk())
        {
            if(request is null)
            {
                request = new Request();
            }

            auto currentChunk = currentChunk.idup;
            request.feed(currentChunk);

            Request.Status status = request.getStatus();
            if(status == Request.Status.NotFinished)
            {
                return;
            }

            processedRequest += 1;
            routeRequest(hosts);
        }
    }

    private void routeRequest(Host[] hosts)
    {
        mixin(Tracer);
        scope(exit) request = null;
        
        if(request.hasError() || !request.hasHostHeader())
        {
            log.warning("Malformed request => Bad Request");
            auto badRequestResponse = new BadRequestResponse();
            sendResponse(badRequestResponse);
            close();
        }
        else
        {
            log.info("Routing request...");
            foreach(host ; hosts)
            {
                if(host.matchHostHeader(request))
                {
                    Response response = host.dispatch(request);
                    sendResponse(response);
                    return;
                }
            }
        }

        log.warning("Host not found => Not Found");
        auto hostNotFoundResponse = new NotFoundResponse();
        sendResponse(hostNotFoundResponse);
    }

    private bool sendResponse(Response response)
    {
        bool writeResult = false;
        if(response !is null)
        {
            string buffer = response.get();
            writeResult = writeChunk(buffer);
            if(response.hasHeader(Header.Connection, "close"))
            {
                close();
            }
        }
        return writeResult;
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
            close();
            return false;
        }
        currentChunk = buffer[0 .. datalength];
        refreshKeepAlive();
        log.info("Received ", datalength, " bytes from ", address, "\n\"\n", currentChunk, "\"");
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
            log.info("Connection from ", address, " closed.");
            return false;
        }
        log.info("Sent ", datalength, " bytes to ", address, "\n\"\n", data, "\n\"");
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

    private:
        
        char[] currentChunk;
        Address address;
        Socket handle;
        Duration keepAliveDuration;
        TickDuration keepAliveTimer;
        uint maxRequest;
        uint processedRequest;
        Request request;
}

