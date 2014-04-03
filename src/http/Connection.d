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
        Transaction[] m_queue;
        bool m_keepalive = true;
        uint m_syncWatermark;
    }

    public
    {
        this(Socket a_socket, Config a_config)
        {
            mixin(Tracer);
            m_socket = a_socket;
            m_address = m_socket.remoteAddress();
            m_config = a_config;
            m_syncWatermark = m_config.options[Parameter.LIMIT_SYNCTREAT].get!(uint);
            m_maxRequest = m_config.options[Parameter.MAX_REQUEST].get!(uint);
            m_socket.blocking = false;
            m_socket.setNoDelay(m_config.options[Parameter.TCP_NODELAY].get!(bool));
            m_socket.setCork(m_config.options[Parameter.TCP_CORK].get!(bool));
            m_socket.setLinger(m_config.options[Parameter.TCP_LINGER].get!(bool));
            m_request.init();
        }

        void recv()
        {
            mixin(Tracer);
            static char[65535] buffer;
            auto nread = read(buffer);
            if(nread)
            {
                if(!m_request.feed(buffer[0..nread]))
                {
                    // can't feed our request (limit size ?)
                    log.trace("Entity feeding too large");
                    auto entityTooLargeResponse = new EntityTooLargeResponse;
                    write(entityTooLargeResponse.get());
                    m_keepalive = false;
                }
                else
                {
                    auto transaction = Transaction.get(m_request, m_config);
                    if(transaction)
                    {
                        if(transaction.response.length <= m_syncWatermark)
                        {
                            m_keepalive = write(transaction.response) && transaction.keepalive;
                        }
                        else
                        {
                            m_queue ~= transaction;
                        }

                        m_processedRequest++;
                        m_request = Request();
                        m_request.init();
                    }
                    else
                    {
                        log.trace("No response ready");
                        m_keepalive = m_request.status == Request.Status.NotFinished;
                    }
                }
            }
            else
            {
                m_keepalive = false;
            }
        }

        void send()
        {
            mixin(Tracer);
            if(empty)
            {
                log.trace("Empty queue on ", handle());
                return;
            }
            auto transaction = m_queue.front();
            m_queue.popFront();
            m_keepalive = write(transaction.response) && transaction.keepalive;
            log.trace(m_keepalive ? "Keep alive !" : "DONT keep alive !");
        }

        @property auto handle()
        {
            return socket.handle;
        }

        @property auto socket()
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
            return m_keepalive && m_processedRequest < m_maxRequest;
        }

        @property auto address()
        {
            return m_address;
        }

        @property auto empty()
        {
            return m_queue.empty();
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
                log.trace("Disconnection on ", handle);
                return 0;
            }
            log.trace("Size of chunk read ", datalength);
            return datalength;
        }

        bool write(Response response)
        {
            mixin(Tracer);
            auto vecs = response.vecs;
            auto datalength = writev(socket.handle(), vecs.ptr, cast(int)vecs.length);
            if (datalength == Socket.ERROR)
            {
                log.warning("Connection error ", m_address, " on ", handle);
                return false;
            }
            else if(datalength == 0)
            {
                log.warning("Connection from ", m_address, " closed on ", handle, " (", lastSocketError(), ")");
                return false;
            }
            else if(datalength < response.length)
            {
                log.warning("Data not sent on ", handle, " : ", datalength, " < ", response.length, " (", lastSocketError(), ")");
            }
            return true;
        }

        bool write(char[] chunk)
        {
            mixin(Tracer);
            auto datalength = socket.send(chunk);
            log.trace("Chunk written : ", chunk);
            log.trace("Size of chunk to write : ", chunk.length, ", size written : ", datalength);
            if (datalength == Socket.ERROR)
            {
                log.warning("Connection error ", m_address, " on ", handle);
                return false;
            }
            else if(datalength == 0)
            {
                log.warning("Connection from ", m_address, " closed on ", handle, " (", lastSocketError(), ")");
                return false;
            }
            else if(datalength < chunk.length)
            {
                log.warning("Data not sent on ", handle, " : ", datalength, " < ", chunk.length, " (", lastSocketError(), ")");
            }
            return true;
        }
    }
}
