module dhttpd;

import core.thread;
import std.socket;
import std.conv;

import http.protocol.Status;
import http.protocol.Mime;

import http.server.Server;
import http.server.Worker;
import http.server.Directory;
import http.server.Proxy;
import http.server.Route;
import http.server.VirtualHost;
import http.server.Config;
import http.server.Options;
import http.server.Poller;

import dlog.Logger;
import EvLoop;
import ZmqLoop;
import utils;

void startThreads(uint nbThreads)
{
    mixin(Tracer);
    Options options;
    options[Parameter.MIME_TYPES] = new MimeMap();
    options[Parameter.DEFAULT_MIME] = "application/octet-stream";
    options[Parameter.FILE_CACHE] = true;
    options[Parameter.HTTP_CACHE] = true;
    options[Parameter.MAX_CONNECTION] = 60;
    options[Parameter.BACKLOG] = 2048;
    options[Parameter.KEEP_ALIVE_TIMEOUT] = dur!"seconds"(60);
    options[Parameter.TCP_DEFER] = true;
    options[Parameter.TCP_REUSEPORT] = true;
    options[Parameter.TCP_REUSEADDR] = true;
    options[Parameter.MAX_REQUEST] = 1_000_000u;
    options[Parameter.MAX_HEADER] = 100;
    options[Parameter.MAX_REQUEST_SIZE] = 1000000;
    options[Parameter.SERVER_STRING] = "dhttpd";
    options[Parameter.INSTALL_DIR] = installDir();
    options[Parameter.ROOT_DIR] = installDir();
    options[Parameter.BAD_REQUEST_FILE] = installDir() ~ "/public/400.html";
    options[Parameter.NOT_FOUND_FILE] =   installDir() ~ "/public/404.html";
    options[Parameter.NOT_ALLOWED_FILE] = installDir() ~ "/public/405.html";
    
    auto zmqLoop = new ZmqLoop;

    // handlers
    auto mainDir    = new Directory("/public", "index.html", options);
    auto mainWorker = new Worker(zmqLoop.context(), "tcp://127.0.0.1:9999", "tcp://127.0.0.1:9998");

    // routes
    auto mainRoute  = new Route("^/main", mainDir);

    // hosts
    auto mainHost   = new VirtualHost(["www.dhttpd.fr"], [mainRoute]);

    // config
    auto mainConfig = new Config(options, ["0.0.0.0"], [8080], [mainHost], mainHost);

    /*
    auto zmqLoop = new ZmqLoop();
    auto proxyHandler = new Proxy();
    auto workerRoute = new Route("^/worker", workerHandler);
    auto proxyRoute = new Route("^/proxy", proxyHandler);
    */
    auto loop = new DefaultEvLoop();

    if(nbThreads == 1)
    {
        auto mainServer = new Server(loop, mainConfig);
        loop.run();
    }
    else if(nbThreads <= totalCPUs)
    {
        ThreadGroup workers = new ThreadGroup();
        foreach(threadIndex ; 0..nbThreads)
        {
            log.trace("New thread ", threadIndex);
            auto worker = new ServerWorker(loop, mainConfig);
            worker.start();
            workers.add(worker);
        }

        loop.run();
        log.info("Waiting for worker thread to join");
        workers.joinAll();
    }
    else
    {
        log.error("Invalid thread count (1 <= t <= ", totalCPUs, ") ");
    }
}

int main(string[] args)
{
    try
    {
        mixin(Tracer);
        uint nbThreads = 1;
        ushort logPort = 9090;
        string logIp = "127.0.0.1";

        import std.getopt;
        getopt(
            args,
            std.getopt.config.stopOnFirstNonOption,
            "threads|t",    &nbThreads,
            "logport|lp",   &logPort,
            "logip|li",     &logIp
        );

        version(assert)
        {
            log.register(new ConsoleLogger);
        }
        //log.register(new TcpLogger(logIp, logPort));
        log.register(new ZmqLogger("tcp://" ~ logIp ~ ":" ~ to!string(logPort)));
        log.info("Threads to create : ", nbThreads);
        
        if(!nbThreads)
        {
            log.error("One thread minimum allowed");
            return 0;
        }

        if(nbThreads > totalCPUs)
        {
            log.warning("Threads number is not optimal");
        }

        log.info("Entering child process");
        startThreads(nbThreads);
    }
    catch(Exception e)
    {
        log.error(e);
        return -1;
    }
    log.stats();
    return 0;
}

/*
    defaultHandlers[Status.BadRequest] = new ErrorHandler();
    defaultHandlers[Status.Unauthorized] = new ErrorHandler();
    defaultHandlers[Status.Payment] = new ErrorHandler();
    defaultHandlers[Status.Forbidden] = new ErrorHandler();
    defaultHandlers[Status.NotFound] = new ErrorHandler();
    defaultHandlers[Status.NotAllowed] = new ErrorHandler();
    defaultHandlers[Status.NotAcceptable] = new ErrorHandler();
    defaultHandlers[Status.ProxyAutg] = new ErrorHandler();
    defaultHandlers[Status.TimeOut] = new ErrorHandler();
    defaultHandlers[Status.Conflict] = new ErrorHandler();
    defaultHandlers[Status.Gone] = new ErrorHandler();
    defaultHandlers[Status.LengthRequired] = new ErrorHandler();
    defaultHandlers[Status.PrecondFailed] = new ErrorHandler();
    defaultHandlers[Status.RequestEntityTooLarge] = new ErrorHandler();
    defaultHandlers[Status.RequestUriTooLarge] = new ErrorHandler();
    defaultHandlers[Status.UnsupportedMediaType] = new ErrorHandler();
    defaultHandlers[Status.RequestedRangeNotSatisfiable] = new ErrorHandler();
    defaultHandlers[Status.ExpectationFailed] = new ErrorHandler();
    defaultHandlers[Status.InternalError] = new ErrorHandler();
    defaultHandlers[Status.NotImplemented] = new ErrorHandler();
    defaultHandlers[Status.BadGateway] = new ErrorHandler();
    defaultHandlers[Status.ServiceUnavailable] = new ErrorHandler();
    defaultHandlers[Status.GatewayTimeOut] = new ErrorHandler();
    defaultHandlers[Status.UnsupportedVersion] = new ErrorHandler();
*/
