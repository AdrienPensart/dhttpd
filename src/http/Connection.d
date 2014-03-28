module http.Connection;

import std.typecons;
import std.socket;
import std.array;
import std.file;
import core.time;

import http.protocol.Protocol;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Status;
import http.protocol.Header;

import http.Config;
import http.Options;
import http.VirtualHost;
import http.handler.Handler;

import dlog.Logger;
import crunch.Caching;

class Connection : ReferenceCounter!Connection
{
    private
    {
        static Cache!(uint, Response) m_cache;
        Address m_address;
        Socket m_socket;
        Config m_config;
        Request m_request;

        uint maxRequest;
        uint processedRequest;
    }

    public
    {
        this(Socket a_socket, Config a_config)
        {
            mixin(Tracer);
            m_socket = a_socket;
            m_address = m_socket.remoteAddress();
            m_config = a_config;
            maxRequest = m_config.options[Parameter.MAX_REQUEST].get!(uint);
            m_socket.blocking = false;
            //enum TCP_CORK = 3;
            //m_socket.setOption(SocketOptionLevel.TCP, cast(SocketOption)TCP_CORK, true);
            
            m_socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
            Linger linger;
            linger.on = 1;
            linger.time = 1;
            m_socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, linger);

            m_request.init();
        }

        Response computeResponse()
        {
            Response m_response = null;
            m_request.parse();
            final switch(m_request.status())
            {
                case Request.Status.NotFinished:
                    log.trace("Request not finished");
                    break;
                case Request.Status.Finished:
                    log.trace("Request ready : \n\"\n", m_request.get(), "\"");
                    
                    auto m_tuple = m_config.dispatch(m_request);
                    m_response = m_tuple[0];
                    //m_handler = m_tuple[1];

                    if(m_response is null)
                    {
                        log.trace("Host not found and no fallback => Not Found");
                        m_response = new NotFoundResponse(m_config.options[Parameter.NOT_FOUND_FILE].toString());
                    }

                    if(m_request.keepalive && m_request.protocol == HTTP_1_0)
                    {
                        m_response.headers[FieldConnection] = KeepAlive;
                    }
                    
                    m_response.keepalive = m_request.keepalive;
                    m_response.protocol = m_request.protocol;
                    m_response.headers[FieldServer] = m_config.options[Parameter.SERVER_STRING].toString();                
                    break;
                case Request.Status.HasError:
                    // don't cache malformed request
                    log.trace("Malformed request => Bad Request");
                    m_response = new BadRequestResponse(m_config.options[Parameter.BAD_REQUEST_FILE].toString());
                    m_response.headers[FieldConnection] = "close";
                    m_response.protocol = m_request.protocol;
                    break;
            }
            return m_response;
        }

        bool synctreat()
        {
            mixin(Tracer);
            auto buffer = readChunk();
            if(buffer.length)
            {
                log.trace("Feeding data size : ", buffer.length);
                m_request.feed(buffer);
                Response m_response = m_cache.get(m_request.hash, computeResponse());
                if(m_response !is null)
                {
                    processedRequest++;
                    m_request = Request();
                    m_request.init();
                    auto data = m_response.get();
                    return writeChunk(data) && m_response.keepalive;
                }
            }
            log.trace("No response");
            return false;
        }

        /*
        private Transaction[] queue;
        bool recv()
        {
            mixin(Tracer);
            auto buffer = readChunk();
            if(!buffer.length)
            {
                return false;
            }
            
            if(currentRequest is null)
            {
                currentRequest = new Request();
            }

            log.trace("Feeding request on ", handle());
            currentRequest.feed(buffer);

            Transaction transaction = new Transaction(m_config, currentRequest);
            if(transaction.get() !is null)
            {
                log.trace("Pushing transaction into queue for ", handle());
                processedRequest++;
                queue ~= transaction;
                currentRequest = null;
            }
            return true;
        }

        bool send()
        {
            mixin(Tracer);
            if(queue.empty)
            {
                log.trace("Empty queue on ", handle());
                return true;
            }

            auto transaction = queue.front();
            queue.popFront();
            return writeChunk(transaction.response.get()) && transaction.keepalive;
        }

        auto empty()
        {
            return queue.empty();
        }
        */

        auto handle()
        {
            return socket.handle;
        }

        auto socket()
        {
            return m_socket;
        }
            
        auto setMaxRequest(uint a_maxRequest)
        {
            maxRequest = a_maxRequest;
        }

        void close()
        {
            mixin(Tracer);
            log.trace("Closing ", address);
            m_socket.close();
        }

        void shutdown()
        {
            mixin(Tracer);
            log.trace("Shutting down ", address, " on ", handle());
            if(m_socket.isAlive)
            {
                this.socket.shutdown(SocketShutdown.BOTH);
            }
        }

        auto alive()
        {
            return socket.isAlive && socket.handle != -1;
        }

        auto tooMuchRequests()
        {
            /*
            log.trace("Processed requests : ", processedRequest);
            log.trace("Max requests : ", maxRequest);
            log.trace("Too much request : ", processedRequest > maxRequest);
            */
            return processedRequest > maxRequest;
        }

        auto valid()
        {
            return !tooMuchRequests() && alive();
        }

        @property auto address()
        {
            return m_address;
        }
    }

    private
    {
        char[] readChunk()
        {
            mixin(Tracer);
            static char[1024] buffer;
            auto datalength = socket.receive(buffer);
            if (datalength == Socket.ERROR)
            {
                log.warning("Socket error : ", lastSocketError());
                return [];
            }
            else if(datalength == 0)
            {
                log.trace("Disconnection on ", handle());
                return [];
            }
            log.trace("Read chunk : ", buffer[0..datalength]);
            return buffer[0..datalength];
        }

        bool writeChunk(string data)
        {
            mixin(Tracer);
            log.trace("Chunk to be written : ", data);
            auto datalength = socket.send(data);
            /*
            import core.sys.posix.sys.uio;
            auto iov = iovec();
            iov.iov_base = cast(void*)data.ptr;
            iov.iov_len = data.length;
            auto datalength = writev(socket.handle(), &iov, 1);
            */
            if (datalength == Socket.ERROR)
            {
                log.warning("Connection error ", m_address, " on ", handle());
                return false;
            }
            else if(datalength == 0)
            {
                log.warning("Connection from ", m_address, " closed on ", handle(), " (", lastSocketError(), ")");
                return false;
            }
            else if(datalength < data.length)
            {
                log.warning("Data not sent on ", handle(), " : ", datalength, " < ", data.length, " (", lastSocketError(), ")");
            }
            return true;
        }
    }
}
