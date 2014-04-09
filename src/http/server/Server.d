module http.server.Server;

import core.thread;
import std.conv;

import crunch.Utils;
import dlog.Logger;
import dlog.ZmqLogger;
import dlog.UdpLogger;
import dlog.TcpLogger;

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

void registerLoggers(Config config)
{    
    auto consoleLogging = config.options.get!bool(Parameter.CONSOLE_LOGGING);
    if(consoleLogging)
    {
        log.register(new ConsoleLogger);
    }

    auto zmqLogHost = config.options.get!string(Parameter.ZMQ_LOG_HOST);
    auto zmqLogPort = config.options.get!ushort(Parameter.ZMQ_LOG_PORT);
    log.register(new ZmqLogger("tcp://" ~ zmqLogHost ~ ":" ~ to!string(zmqLogPort)));

    auto tcpLogHost = config.options.get!string(Parameter.TCP_LOG_HOST);
    auto tcpLogPort = config.options.get!ushort(Parameter.TCP_LOG_PORT);
    log.register(new TcpLogger(tcpLogHost, tcpLogPort));

    auto udpLogHost = config.options.get!string(Parameter.UDP_LOG_HOST);
    auto udpLogPort = config.options.get!ushort(Parameter.UDP_LOG_PORT);
    log.register(new UdpLogger(udpLogHost, udpLogPort));

    auto logFile = config.options.get!string(Parameter.FILE_LOG);
    log.register(new FileLogger(logFile));
}

class Server
{
    private
    {
        Config m_config;
        EvLoop m_loop;
    }

    @property EvLoop loop()
    {
        return m_loop;
    }

    @property Config config()
    {
        return m_config;
    }

    @property ref Options options()
    {
        return m_config.options;
    }

    this(EvLoop a_loop, Config a_config)
    {
        this.m_loop = a_loop;
        this.m_config = a_config;
        FilePoller.loop = m_loop;

        auto badRequestPath = options.get!string(Parameter.BAD_REQUEST_PATH);
        options[Parameter.BAD_REQUEST_RESPONSE] = new Response(Status.BadRequest, new FileEntity(badRequestPath));

        auto notFoundPath = options.get!string(Parameter.NOT_FOUND_PATH);
        options[Parameter.NOT_FOUND_RESPONSE] =   new Response(Status.NotFound, new FileEntity(notFoundPath));

        auto notAllowedPath = options.get!string(Parameter.NOT_ALLOWED_PATH);
        options[Parameter.NOT_ALLOWED_RESPONSE] = new Response(Status.NotAllowed, new FileEntity(notAllowedPath));

        auto unauthorizedPath = options.get!string(Parameter.UNAUTHORIZED_PATH);
        options[Parameter.UNAUTHORIZED_RESPONSE] = new Response(Status.Unauthorized, new FileEntity(unauthorizedPath));

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
    private
    {
        EvLoop m_loop;
        Server m_server;
        Config m_config;
    }

    this(EvLoop a_loop, Config a_config)
    {
        m_config = a_config;
        m_loop = a_loop;
        super(&run);
    }

    void run()
    {
        try
        {
            registerLoggers(m_config);
            m_server = new Server(m_loop, m_config);
            m_loop.run();
        }
        catch(Exception e)
        {
            log.error(e.msg);
        }
    }
}
