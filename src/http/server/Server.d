module http.server.Server;

import core.thread;
import std.conv;

import dlog.Logger;

import http.server.Options;
import http.server.Config;
import http.server.Poller;

import EvLoop;

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
        /*
        version(assert)
        {
            auto timedStatistic = new LogStatistic(m_loop);
            m_loop.addEvent(timedStatistic);
        }
        */
        foreach(address ; config.addresses)
        {
            log.info("Listening on : ", address);
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
            version(assert)
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
