module http.server.Connection;

import std.socket;
import std.array;
import std.file;
import core.time;

import http.protocol.Protocol;
import http.poller.FilePoller;

import http.server.Transaction;
import http.server.Config;
import http.server.Options;
import http.server.VirtualHost;
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
        FileSender m_fs;
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
            //m_socket.setCork(m_config.options[Parameter.TCP_CORK].get!(bool));
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
                    auto entityTooLargeResponse = m_config.options[Parameter.ENTITY_TOO_LARGE_RESPONSE].get!(Response);
                    writeAll(entityTooLargeResponse.header);
                    m_keepalive = false;
                }
                else
                {
                    buildTransaction();
                }
            }
        }

        void send()
        {
            mixin(Tracer);
            if(empty)
            {
                log.trace("Empty queue on ", handle());
            }

            auto transaction = m_queue.front();
            if(transaction.response.send(this))
            {
                log.trace("File transfer completed, dequeue transaction");
                m_queue.popFront();
            }
        }

        bool writeAll(char[] chunk)
        {
            mixin(Tracer);
            size_t sent = 0;
            while(sent < chunk.length)
            {
                auto datalength = write(chunk[sent..$]);
                if(!datalength)
                {
                    return false;
                }
                sent += datalength;
            }
            return true;
        }

        bool writeFile(FilePoller * a_poller)
        {
            return m_fs.send(m_socket, a_poller);
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
        void buildTransaction()
        {
            mixin(Tracer);
            auto transaction = Transaction.get(m_request, m_config);
            if(transaction)
            {
                if(!transaction.commit(this))
                {
                    m_queue ~= transaction;
                }
                prepareNextRequest();
                m_keepalive = m_keepalive && transaction.keepalive;
                log.trace(m_keepalive ? "KEEP ALIVE!" : "DONT KEEP ALIVE!");
            }
            else
            {
                log.trace("No response ready");
                m_keepalive = m_request.status == Request.Status.NotFinished;
            }
        }

        void prepareNextRequest()
        {
            mixin(Tracer);
            m_processedRequest++;
            m_request = Request();
            m_request.init();
        }

        size_t read(char[] chunk)
        {
            mixin(Tracer);
            auto datalength = socket.receive(chunk);
            if (datalength == Socket.ERROR)
            {
                log.warning("Read socket error on ", m_address, " with ", handle, " (", lastSocketError(), ")");
                m_keepalive = false;
                datalength = 0;
            }
            else if(datalength == 0)
            {
                log.trace("Read disconnection on ", m_address, " with ", handle, " (", lastSocketError(), ")");
                m_keepalive = false;
            }
            log.trace("Size of chunk read ", datalength);
            return datalength;
        }

        size_t write(char[] chunk)
        {
            /*
            auto vecs = response.vecs;
            auto datalength = writev(socket.handle(), vecs.ptr, cast(int)vecs.length);
            */
            log.trace("Writing chunk size ", chunk.length, " : ", chunk);
            auto datalength = socket.send(chunk);
            if (datalength == Socket.ERROR)
            {
                log.warning("Write socket error on ", m_address, " with ", handle, " (", lastSocketError(), ")");
                m_keepalive = false;
                datalength = 0;
            }
            else if(datalength == 0)
            {
                log.warning("Write socket disconnection on ", m_address, " with ", handle, " (", lastSocketError(), ")");
                m_keepalive = false;
            }
            else if(datalength < chunk.length)
            {
                log.warning("All data not sent on ", m_address, " with ", handle, ", ", datalength, " < ", chunk.length, " (", lastSocketError(), ")");
            }
            return datalength;
        }
    }
}
