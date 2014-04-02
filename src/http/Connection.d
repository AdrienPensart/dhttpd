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
import crunch.Utils;


class Connection : ReferenceCounter!(Connection)
{
    private
    {
        Address m_address;
        Socket m_socket;
        Config m_config;
        Request m_request;
        uint m_maxRequest;
        uint m_processedRequest;
    }

    public
    {
        this(Socket a_socket, Config a_config)
        {
            mixin(Tracer);
            m_socket = a_socket;
            m_address = m_socket.remoteAddress();
            m_config = a_config;
            m_maxRequest = m_config.options[Parameter.MAX_REQUEST].get!(uint);
            m_socket.blocking = false;
            m_socket.setNoDelay(m_config.options[Parameter.TCP_NODELAY].get!(bool));
            m_socket.setLinger(m_config.options[Parameter.TCP_LINGER].get!(bool));
            m_request.init();
        }

        bool synctreat()
        {
            mixin(Tracer);
            static char[65535] buffer;
            auto nread = read(buffer);
            bool result = false;
            if(nread)
            {
                if(!m_request.feed(buffer[0..nread]))
                {
                    // can't feed our request (limit size ?)
                    log.trace("Entity feeding too large");
                    auto entityTooLargeResponse = new EntityTooLargeResponse;
                    write(entityTooLargeResponse.get());
                    return false;
                }

                auto transaction = Transaction.get(m_request, m_config);
                if(transaction)
                {
                    m_processedRequest++;
                    m_request = Request();
                    m_request.init();
                    auto data = transaction.response.get();
                    if(write(data))
                    {
                        if(transaction.keepalive)
                        {
                            log.trace("Keep alive !");
                            result = true;
                        }
                        else
                        {
                            log.trace("DONT keep alive !");
                            result = false;
                        }
                    }
                }
                else
                {
                    log.trace("No response ready");
                    result = m_request.status == Request.Status.NotFinished;
                }
            }
            return result;
        }

        auto handle()
        {
            return socket.handle;
        }

        auto socket()
        {
            return m_socket;
        }
        
        @property auto maxRequest()
        {
            return m_maxRequest;
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

        @property auto valid()
        {
            return m_processedRequest < m_maxRequest && socket.isAlive && socket.handle != -1;
        }

        @property auto address()
        {
            return m_address;
        }
    }

    private
    {
        size_t read(char[] chunk)
        {
            mixin(Tracer);
            auto datalength = socket.receive(chunk);
            if (datalength == Socket.ERROR)
            {
                log.warning("Socket error : ", lastSocketError());
                return 0;
            }
            else if(datalength == 0)
            {
                log.trace("Disconnection on ", handle());
                return 0;
            }
            log.trace("Size of chunk read ", datalength);
            return datalength;
        }

        bool write(char[] chunk)
        {
            mixin(Tracer);
            auto datalength = socket.send(chunk);
            log.trace("Size of chunk to write : ", chunk.length, ", size written : ", datalength);
            /*
            import core.sys.posix.sys.uio;
            auto iov = iovec();
            iov.iov_base = cast(void*)chunk.ptr;
            iov.iov_len = chunk.length;
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
            else if(datalength < chunk.length)
            {
                log.warning("Data not sent on ", handle(), " : ", datalength, " < ", chunk.length, " (", lastSocketError(), ")");
            }
            return true;
        }
    }
}
