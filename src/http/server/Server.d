module http.server.Server;

import core.thread;

import dlog.Logger;

import http.server.Config;
import http.server.Poller;

import EventLoop;
import crunch.Wrap;

class ServerImpl
{
    Config m_config;
    ev_loop_t * m_loop;
    
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

    this(ev_loop_t * loop, Config config)
    {
        this.m_loop = loop;
        this.m_config = config;
        
        foreach(address ; config.addresses)
        {
            log.info("Listening on : ", address);
            auto listenerPoller = new ListenerPoller(this, address);
        }
    }
}

alias ServerImpl Server;
//alias Wrap!(ServerImpl) Server;

class ServerWorker : Thread
{
    this(Config config)
    {
        super(&run);
        m_loop = new LibevLoop();
        m_server = new Server(m_loop.loop(), config);
    }

    void run()
    {
        mixin(Tracer);
        m_loop.run();
    }
    
    private LibevLoop m_loop;
    private Server m_server;
}
