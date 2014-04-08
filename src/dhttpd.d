module dhttpd;

import std.datetime;
import std.conv;
import std.uuid;

import dlog.Logger;
import crunch.Utils;

import http.protocol.Protocol;
import http.server.Server;
import http.handler.All;

import loop.All;

Config createConfig(ref Options options)
{
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

    options[Parameter.MAX_BLOCK] = 65535u;
    options[Parameter.MAX_REQUEST] = 1_000_000u; // max request allowed per connection
    options[Parameter.MAX_HEADER] = 8192; // max header size allowed
    options[Parameter.MAX_GET_REQUEST] = 16384;
    options[Parameter.MAX_PUT_REQUEST] = 16384;
    options[Parameter.MAX_POST_REQUEST] = 16384;

    options[Parameter.MAX_CONNECTION] = 1000; // global maximum connection allowed
    options[Parameter.SERVER_STRING] = "dhttpd";
    options[Parameter.INSTALL_DIR] = installDir();
    options[Parameter.ROOT_DIR] = installDir();

    options[Parameter.ENTITY_TOO_LARGE_RESPONSE] = new Response(Status.RequestEntityTooLarge);
    options[Parameter.PRECOND_FAILED_RESPONSE] = new Response(Status.PrecondFailed);

    options[Parameter.BAD_REQUEST_PATH] = installDir() ~ "/public/400.html";
    options[Parameter.NOT_FOUND_PATH] = installDir() ~ "/public/404.html";
    options[Parameter.NOT_ALLOWED_PATH] = installDir() ~ "/public/405.html";
    options[Parameter.UNAUTHORIZED_PATH] = installDir() ~ "/public/401.html";

    //import http.Transaction;
    //Transaction.enable_cache(options[Parameter.HTTP_CACHE].get!(bool));

    //auto mainWorker = new Worker(zmqLoop.context(), "tcp://127.0.0.1:9999", "tcp://127.0.0.1:9998");

    // routes
    auto publicDir  = new Directory(&options, "public", "index.html");
    auto rootRoute  = new Route("^/", publicDir);
    auto mainRoute  = new Route("^/main", publicDir);

    auto basicDir = new Directory(&options, "private", "home.html");
    auto basicAuthenticationFilter = new BasicAuthentication(&options, "private", "crunch", "test");
    basicDir.addInputFilter(basicAuthenticationFilter);
    auto basicRoute = new Route("^/basic", basicDir);

    auto digestDir = new Directory(&options, "private", "home.html");
    auto digestAuthenticationFilter = new DigestAuthentication();
    digestDir.addInputFilter(digestAuthenticationFilter);
    auto digestRoute = new Route("^/digest", digestDir);

    auto movedRedirect = new Redirect(Status.MovedPerm, "http://www.google.fr");
    auto foundRedirect = new Redirect(Status.Found, "http://www.bing.com");

    auto movedRoute = new Route("^/redirect_301", movedRedirect);
    auto foundRoute = new Route("^/redirect_302", foundRedirect);

    auto docDir     = new Directory(&options, "doc");
    auto mainDoc    = new Route("^/doc",  docDir);

    auto videosDir  = new Directory(&options, "/home/crunch/videos");
    auto mainVideos = new Route("^/videos", videosDir);

    // hosts
    auto mainHost   = new VirtualHost(["www.dhttpd.fr"], [basicRoute, digestRoute, movedRoute, foundRoute, mainRoute, mainDoc, mainVideos, rootRoute]);

    // config
    auto mainConfig = new Config(&options, ["0.0.0.0"], [8080], [mainHost], mainHost);

    return mainConfig;
}

void startThreads(Config config)
{
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

    auto gcmode = config.options.get!GCMode(Parameter.GC_MODE);
    auto gctimer = config.options.get!double(Parameter.GC_TIMER);
    auto garbageCollectionEvent = new GCEvent(evLoop, gcmode, gctimer);
    evLoop.addEvent(garbageCollectionEvent);

    auto logStatisticEvent = new LogStatisticEvent(evLoop);
    evLoop.addEvent(logStatisticEvent);

    auto threads = config.options.get!uint(Parameter.THREADS);

    log.trace("Threads to create : ", threads);
    if(threads == 0)
    {
        log.error("One thread minimum allowed");
    }
    else if(threads == 1)
    {
        auto server = new Server(evLoop, config);
        evLoop.run();
    }
    else if(threads <= totalCPUs)
    {
        import core.thread;
        ThreadGroup workers = new ThreadGroup();
        foreach(threadIndex ; 0..threads)
        {
            auto child = new EvLoop();
            log.info("Adding child ", child.id, " to parent ", defaultLoop);
            interruptionEvent.addChild(child);
            auto worker = new ServerWorker(child, config);
            worker.start();
            workers.add(worker);
        }

        evLoop.run();
        log.info("Waiting for worker thread to join");
        workers.joinAll();
    }
    else
    {
        log.error("Invalid thread count (1 <= ", threads, " <= ", totalCPUs, ") ");
    }
}

int main(string[] args)
{
    try
    {
        // sendfile syscall can emit sigpipe when a client disconnect
        // sigpipe kill the server by default, we don't want that
        ignoreSignalSIGPIPE();

        // zmq logging supported
        string zmqLogHost = "127.0.0.1";
        ushort zmqLogPort = 9090;
        
        // tcp logging supported
        string tcpLogHost = "127.0.0.1";
        ushort tcpLogPort = 9091;

        // udp logging supported
        string udpLogHost = "127.0.0.1";
        ushort udpLogPort = 9092;

        // console logging supported
        bool consoleLogging = false;

        // by default, the server won't create any additional thread
        uint threads = 1;

        // memory management options of D language
        // by default we let the runtime manage our memory
        GCMode gcmode = GCMode.automatic;
        // when gcmode is on "timed", the memory is garbaged everty n seconds
        double gctimer = 10.0;

        import std.getopt;
        getopt(
            args,
            std.getopt.config.stopOnFirstNonOption,
            "console|c",  &consoleLogging,
            "threads|t",  &threads,

            "gcmode|gcm", &gcmode,
            "gctimer|gct",&gctimer,

            "zmqhost|zh", &zmqLogHost,
            "zmqport|zp", &zmqLogPort,
            "tcphost|lh", &tcpLogHost,
            "tcpport|tp", &tcpLogPort,
            "udphost|uh", &udpLogHost,
            "udpport|up", &udpLogPort
        );

        if(consoleLogging)
        {
            log.register(new ConsoleLogger);
        }

        log.register(new TcpLogger(tcpLogHost, tcpLogPort));
        log.register(new ZmqLogger("tcp://" ~ zmqLogHost ~ ":" ~ to!string(zmqLogPort)));
        log.register(new UdpLogger(udpLogHost, udpLogPort));

        Options options;
        options[Parameter.THREADS] = threads;
        options[Parameter.GC_MODE] = gcmode;
        options[Parameter.GC_TIMER] = gctimer;

        options[Parameter.ZMQ_LOG_HOST] = zmqLogHost;
        options[Parameter.ZMQ_LOG_PORT] = zmqLogPort;
        
        options[Parameter.TCP_LOG_HOST] = tcpLogHost;
        options[Parameter.TCP_LOG_PORT] = tcpLogPort;

        options[Parameter.UDP_LOG_HOST] = udpLogHost;
        options[Parameter.UDP_LOG_PORT] = udpLogPort;

        options[Parameter.CONSOLE_LOGGING] = consoleLogging;

        auto config = createConfig(options);
        startThreads(config);
    }
    catch(Exception e)
    {
        log.error(e);
        return -1;
    }

    version(autoprofile)
    {
        log.stats();
    }
    return 0;
}
