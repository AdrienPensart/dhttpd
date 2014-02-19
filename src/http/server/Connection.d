module http.server.Connection;

import std.socket;
import std.array;
import std.file;
import core.thread;
import core.time;

import http.protocol.Protocol;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Status;
import http.protocol.Header;

import http.server.Config;
import http.server.Host;

import dlog.Logger;

enum State { TIMEOUT, INTERRUPTED, CLOSED, DATA, REQUEST };

class Connection
{
    this(Socket handle, Config config)
    {
        this.handle = handle;
        this.address = handle.remoteAddress();
        this.config = config;
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
        log.trace("Connection ", address, " closed.");
    }

    State handleRequest()
    {
        mixin(Tracer);

        scope auto handleSet = new SocketSet(config[Parameter.MAX_CONNECTION].get!(int) + 1);
        handleSet.add(handle);

        auto selectStatus = Socket.select(handleSet, null, null, dur!"seconds"(1));
        if (selectStatus == -1)
        {
            return State.INTERRUPTED;
        }
        
        if(handleSet.isSet(handle))
        {
            char buffer[1024];
            auto datalength = handle.receive(buffer);
            if (datalength == Socket.ERROR)
            {
                log.error("Connection error on ", address);
                close();
                return State.CLOSED;
            }
            else if(datalength == 0)
            {
                log.trace("No data on ", address);
                close();
                return State.CLOSED;
            }

            if(request is null)
            {
                request = new Request();
            }

            log.trace("Received ", datalength, " bytes from ", address, "\n\"\n", buffer[0 .. datalength], "\"");
            request.feed(buffer[0 .. datalength]);
            Request.Status status = request.getStatus();
            if(status == Request.Status.Finished || status == Request.Status.HasError)
            {
                log.trace("Request ready.");
                processedRequest += 1;
                refreshKeepAlive();
                return State.REQUEST;
            }
            return State.DATA;
        }
        return State.TIMEOUT;
    }

    void routeRequest(Host[] hosts, Host defaultHost)
    {
        mixin(Tracer);
        log.trace("Routing request");
        scope(exit) request = null;
        
        if(request.hasError())
        {
            log.warning("Malformed request => Bad Request");
            auto badRequestResponse = new BadRequestResponse(config[Parameter.BAD_REQUEST_FILE].toString());
            sendResponse(badRequestResponse);
            close();
        }
        else
        {
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

        // not host found, fallback on default host
        if(defaultHost !is null)
        {
            log.warning("Host not found => Fallback on default");
            Response response = defaultHost.dispatch(request);
            sendResponse(response);
        }
        else
        {
            log.warning("Host not found and no default host => Not Found");
            auto hostNotFoundResponse = new NotFoundResponse(config[Parameter.NOT_FOUND_FILE].toString());
            sendResponse(hostNotFoundResponse);
        }
    }

    private bool sendResponse(Response response)
    {
        bool writeResult = false;
        if(response !is null)
        {
            response.headers[Header.Server] = config[Parameter.SERVER_STRING].toString();
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
            log.trace("Connection from ", address, " closed.");
            return false;
        }
        log.trace("Sent ", datalength, " bytes to ", address, "\n\"\n", data, "\n\"");
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

    auto getAddress()
    {
        return address;
    }

    private:

        Config config;
        Address address;
        Socket handle;
        Duration keepAliveDuration;
        TickDuration keepAliveTimer;
        uint maxRequest;
        uint processedRequest;
        Request request;
}
