module http.Connection;

import std.socket;
import std.array;
import std.file;
import core.time;

import http.protocol.Protocol;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Status;
import http.protocol.Header;

import http.Transaction;
import http.Config;
import http.Options;
import http.VirtualHost;
import http.handler.Handler;

import dlog.Logger;

class Connection
{
    private
    {
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

        bool synctreat()
        {
            mixin(Tracer);
            auto buffer = readChunk();
            if(buffer.length)
            {
                log.trace("Feeding data size : ", buffer.length);
                m_request.feed(buffer);
                auto transaction = Transaction.get(m_request, m_config);
                if(transaction !is null)
                {
                    processedRequest++;
                    m_request = Request();
                    m_request.init();
                    auto data = transaction.response.get();
                    if(writeChunk(data))
                    {
                        if(transaction.keepalive)
                        {
                            log.trace("Keep alive !");
                            return true;
                        }
                        else
                        {
                            log.trace("DONT keep alive !");
                            return false;
                        }
                    }
                    else
                    {
                        log.trace("Write failed");
                        return false;
                    }
                }
                log.trace("No response ready");
                return m_request.status == Request.Status.NotFinished;
            }
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
