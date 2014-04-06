module dhttpd;

import core.thread;
import std.socket;
import std.conv;
import std.uuid;

import dlog.Logger;
import crunch.Utils;

import http.Server;
import http.Route;
import http.VirtualHost;
import http.Config;
import http.Options;

import http.handler.Worker;
import http.handler.Directory;
import http.handler.Proxy;

import loop.EvLoop;
import loop.PipeEvent;
import loop.LogStatisticEvent;
import loop.InterruptionEvent;
import loop.GCEvent;

void startThreads(Options options)
{
    mixin(Tracer);

    import http.protocol.Mime;
    options[Parameter.MIME_TYPES] = new MimeMap;
    options[Parameter.DEFAULT_MIME] = "application/octet-stream";
    
    options[Parameter.FILE_CACHE] = true;
    options[Parameter.HTTP_CACHE] = true;

    options[Parameter.BACKLOG] = 16384;
    options[Parameter.KEEP_ALIVE_TIMEOUT] = dur!"seconds"(60);

    options[Parameter.TCP_CORK] = false;
    options[Parameter.TCP_NODELAY] = true;
    options[Parameter.TCP_LINGER] = true;
    options[Parameter.TCP_DEFER] = true;
    options[Parameter.TCP_REUSEPORT] = true;
    options[Parameter.TCP_REUSEADDR] = true;

    options[Parameter.MAX_REQUEST] = 1_000_000u; // max request allowed per connection
    options[Parameter.MAX_HEADER] = 8192; // max header size allowed
    options[Parameter.MAX_GET_REQUEST] = 16384;
    options[Parameter.MAX_PUT_REQUEST] = 16384;
    options[Parameter.MAX_POST_REQUEST] = 16384;

    options[Parameter.MAX_CONNECTION] = 1000; // global maximum connection allowed
    options[Parameter.SERVER_STRING] = "dhttpd";
    options[Parameter.INSTALL_DIR] = installDir();
    options[Parameter.ROOT_DIR] = installDir();
    //import http.Transaction;
    //Transaction.enable_cache(options[Parameter.HTTP_CACHE].get!(bool));

    auto videosDir  = new Directory(options, "/home/crunch/videos");

    auto docDir     = new Directory(options, "doc");

    // handlers
    auto mainDir    = new Directory(options, "public", "index.html");
    //auto mainWorker = new Worker(zmqLoop.context(), "tcp://127.0.0.1:9999", "tcp://127.0.0.1:9998");

    // routes
    auto mainRoute  = new Route("^/main", mainDir);
    auto mainDoc    = new Route("^/doc",  docDir);
    auto mainVideos = new Route("^/videos", videosDir);

    // hosts
    auto mainHost   = new VirtualHost(["www.dhttpd.fr"], [mainRoute, mainDoc, mainVideos]);

    // config
    auto mainConfig = new Config(options, ["0.0.0.0"], [8080], [mainHost], mainHost);

    /*
    import loop.ZmqLoop;
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
    /*
    auto pipeEvent = new PipeEvent(evLoop);
    evLoop.addEvent(pipeEvent);
    */
    auto interruptionEvent = new InterruptionEvent(evLoop);
    evLoop.addEvent(interruptionEvent);

    auto garbageCollectionEvent = new GCEvent(evLoop, options[Parameter.GC_MODE].get!(GCMode), options[Parameter.GC_TIMER].get!(double));
    evLoop.addEvent(garbageCollectionEvent);

    auto logStatisticEvent = new LogStatisticEvent(evLoop);
    evLoop.addEvent(logStatisticEvent);

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

        import core.sys.posix.signal;
        signal(SIGPIPE, SIG_IGN);

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
        log.register(new ZmqLogger("tcp://" ~ logHost ~ ":" ~ to!string(zmqPort)));

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
        options[Parameter.CONSOLE_LOGGING] = consoleLogging;
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
