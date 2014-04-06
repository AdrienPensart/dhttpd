module http.Server;

import core.thread;
import std.conv;

import crunch.Utils;
import dlog.Logger;

import http.Options;
import http.Config;
import http.Transaction;
import http.protocol.Response;
import http.protocol.Status;
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

        options[Parameter.ENTITY_TOO_LARGE_RESPONSE] = new Response(Status.RequestEntityTooLarge);
        options[Parameter.PRECOND_FAILED_RESPONSE] = new Response(Status.PrecondFailed);
        options[Parameter.BAD_REQUEST_RESPONSE] = new Response(Status.BadRequest);
        options[Parameter.NOT_FOUND_RESPONSE] =   new Response(Status.NotFound, installDir() ~ "/public/404.html");
        options[Parameter.NOT_ALLOWED_RESPONSE] = new Response(Status.NotAllowed, installDir() ~ "/public/405.html");

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
