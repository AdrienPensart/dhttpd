module dhttpd;

import core.thread;
import std.socket;
import std.conv;
import std.uuid;

import http.protocol.Status;
import http.protocol.Mime;

import http.Server;
import http.Route;
import http.VirtualHost;
import http.Config;
import http.Options;

import http.handler.Worker;
import http.handler.Directory;
import http.handler.Proxy;

import dlog.Logger;
import crunch.Utils;

import loop.GarbageCollection;
import loop.InterruptionEvent;
import loop.EvLoop;
import loop.ZmqLoop;

__gshared EvLoop [UUID] children;
extern(C) static void interruption (ev_loop_t * a_default_loop, ev_signal * a_interruption_watcher, int revents)
{
    mixin(Tracer);
    log.error("Received SIGINT");
    foreach(childId, child ; children)
    {
        log.info("Sending async break to child ", childId, ", loop : ", child.loop, ", watcher = ", child.stopWatcher);
        ev_async_send(child.loop, child.stopWatcher);
    }
    log.info("Breaking default loop : ", a_default_loop);
    ev_break(a_default_loop, EVBREAK_ALL);
}

void startThreads(Options options)
{
    mixin(Tracer);
    options[Parameter.MIME_TYPES] = new MimeMap;
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

    //Transaction.enable_cache(options[Parameter.HTTP_CACHE].get!(bool));

    // handlers
    auto mainDir    = new Directory("/public", "index.html", options);
    //auto mainWorker = new Worker(zmqLoop.context(), "tcp://127.0.0.1:9999", "tcp://127.0.0.1:9998");

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
    
    version(assert)
    {
        int evMajor = ev_version_major();
        int evMinor = ev_version_minor();
        import std.string : format;
        string evVersion = format("%s.%s", evMajor, evMinor);
        log.info("Libev version : ", evVersion);
    }

    auto defaultLoop = ev_default_loop(EVFLAG_AUTO);
    auto evLoop = new EvLoop(defaultLoop);
    auto interruptionEvent = new InterruptionEvent(evLoop);
    evLoop.addEvent(interruptionEvent);

    auto garbageCollectionEvent = new GarbageCollection(evLoop, options[Parameter.GC_MODE].get!(GCMode), options[Parameter.GC_TIMER].get!(double));
    evLoop.addEvent(garbageCollectionEvent);

    auto nbThreads = options[Parameter.NB_THREADS].get!(uint);
    if(nbThreads == 1)
    {
        auto server = new Server(evLoop, mainConfig);
        evLoop.run();
    }
    else if(nbThreads <= totalCPUs * 2)
    {
        ThreadGroup workers = new ThreadGroup();
        foreach(threadIndex ; 0..nbThreads)
        {
            log.trace("New thread ", threadIndex);
            auto child = new EvLoop();
            log.info("Adding child ", child.id, " to parent ", defaultLoop);
            interruptionEvent.addChild(child);
            auto worker = new ServerWorker(child, mainConfig);
            worker.start();
            workers.add(worker);
        }

        evLoop.run();
        log.info("Waiting for worker thread to join");
        workers.joinAll();
    }
    else
    {
        log.error("Invalid thread count (1 <= t <= ", totalCPUs*2, ") ");
    }
}

int main(string[] args)
{
    try
    {
        mixin(Tracer);
        uint nbThreads = 1;
        ushort zmqPort = 9090;
        ushort tcpPort = 9091;
        string logHost = "127.0.0.1";
        bool consoleLogging = false;

        GCMode gcmode = GCMode.automatic;
        double gctimer = 10.0;

        import std.getopt;
        getopt(
            args,
            std.getopt.config.stopOnFirstNonOption,
            "console|c",  &consoleLogging,
            "gcmode",     &gcmode,
            "gctimer",    &gctimer,
            "threads|t",  &nbThreads,
            "zmqport|zp", &zmqPort,
            "tcpport|tp", &tcpPort,
            "loghost|lh", &logHost
        );

        if(consoleLogging)
        {
            log.register(new ConsoleLogger);
        }
        log.register(new TcpLogger(logHost, tcpPort));
        log.register(new ZmqLogger("tcp://" ~ logHost ~ ":" ~ to!string(tcpPort)));

        log.trace("Threads to create : ", nbThreads);
        if(!nbThreads)
        {
            log.error("One thread minimum allowed");
            return 0;
        }

        if(nbThreads > totalCPUs)
        {
            log.warning("Threads number is not optimal");
        }

        Options options;
        options[Parameter.NB_THREADS] = nbThreads;
        options[Parameter.GC_MODE] = gcmode;
        options[Parameter.GC_TIMER] = gctimer;
        options[Parameter.LOGGER_HOST] = logHost;
        options[Parameter.LOGGER_ZMQ_PORT] = zmqPort;
        options[Parameter.LOGGER_TCP_PORT] = tcpPort;

        startThreads(options);
    }
    catch(Exception e)
    {
        log.error(e);
        return -1;
    }

    version(assert)
    {
        log.stats();
    }
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
