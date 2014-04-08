module http.server.Server;

import core.thread;
import std.conv;

import crunch.Utils;
import dlog.Logger;

public import http.server.Options;
public import http.server.Transaction;
public import http.server.Route;
public import http.server.VirtualHost;
public import http.server.Config;
public import http.server.Connection;

import http.protocol.Protocol;

import http.poller.FilePoller;
import http.poller.ListenerPoller;

import loop.EvLoop;

class Server
{
    Config m_config;
    EvLoop m_loop;
    
    @property auto loop()
    {
        return m_loop;
    }

    @property auto config()
    {
        return m_config;
    }

    @property auto options()
    {
        return m_config.options;
    }

    this(EvLoop a_loop, Config a_config)
    {
        this.m_loop = a_loop;
        this.m_config = a_config;
        FilePoller.loop = m_loop;

        options[Parameter.BAD_REQUEST_RESPONSE] = new Response(Status.BadRequest, new FileEntity(options[Parameter.BAD_REQUEST_PATH].get!(string)));
        options[Parameter.NOT_FOUND_RESPONSE] =   new Response(Status.NotFound, new FileEntity(options[Parameter.NOT_FOUND_PATH].get!(string)));
        options[Parameter.NOT_ALLOWED_RESPONSE] = new Response(Status.NotAllowed, new FileEntity(options[Parameter.NOT_ALLOWED_PATH].get!(string)));
        options[Parameter.UNAUTHORIZED_RESPONSE] = new Response(Status.Unauthorized, new FileEntity(options[Parameter.UNAUTHORIZED_PATH].get!(string)));

        foreach(address ; config.addresses)
        {
            log.info("Listening on : ", address);
            log.info("Loop manager : ", m_loop.loop());
            auto listenerPoller = new ListenerPoller(this, address);
        }
    }
}

class ServerWorker : Thread
{
    this(EvLoop a_loop, Config a_config)
    {
        mixin(Tracer);
        m_config = a_config;
        m_loop = a_loop;
        super(&run);
    }

    void run()
    {
        mixin(Tracer);
        try
        {
            if(m_config.options[Parameter.CONSOLE_LOGGING].get!(bool))
            {
                log.register(new ConsoleLogger);
            }

            m_server = new Server(m_loop, m_config);
            auto logHost = m_server.config.options[Parameter.LOGGER_HOST].get!(string);
            auto zmqPort = m_server.config.options[Parameter.LOGGER_ZMQ_PORT].get!(ushort);
            auto tcpPort = m_server.config.options[Parameter.LOGGER_TCP_PORT].get!(ushort);

            log.register(new TcpLogger(logHost, tcpPort));
            log.register(new ZmqLogger("tcp://" ~ logHost ~ ":" ~ to!string(zmqPort)));

            m_loop.run();
        }
        catch(Exception e)
        {
            log.error(e.msg);
        }
    }
    
    private EvLoop m_loop;
    private Server m_server;
    private Config m_config;
}
