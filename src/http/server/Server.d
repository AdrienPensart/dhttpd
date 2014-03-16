module http.server.Server;

import core.thread;

import dlog.Logger;

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
        
        version(assert)
        {
            auto timedStatistic = new TimedStatistic(m_loop);
        }

        foreach(address ; config.addresses)
        {
            log.info("Listening on : ", address);
            auto listenerPoller = new ListenerPoller(this, address);
        }
    }
}

class ServerWorker : Thread
{
    this(EvLoop parent, Config config)
    {
        mixin(Tracer);
        super(&run);
        m_loop = new EvLoop();
        parent.addChild(m_loop);
        m_server = new Server(m_loop, config);
    }

    void run()
    {
        mixin(Tracer);
        m_loop.run();
    }
    
    private EvLoop m_loop;
    private Server m_server;
}
