import std.getopt;
import std.stdio;
import std.socket;
import std.file;
import std.conv;
import std.path : dirName;
import std.parallelism : totalCPUs;
import std.process;

import dlog.Logger;

import http.protocol.Status;
import http.protocol.Mime;

import http.server.Server;
import http.server.Handler;
import http.server.Directory;
import http.server.Proxy;
import http.server.Route;
import http.server.VirtualHost;
import http.server.Config;
import http.server.Poller;

import EventLoop;

auto installDir()
{
    const string thisdir = dirName(thisExePath());
    return thisdir;
}

void start(uint nbThreads)
{
    mixin(Tracer);
    http.server.Config.Config config;
    config[Parameter.MIME_TYPES] = new MimeMap();
    config[Parameter.DEFAULT_MIME] = "application/octet-stream";
    config[Parameter.FILE_CACHE] = true;
    config[Parameter.HTTP_CACHE] = true;
    config[Parameter.MAX_CONNECTION] = 60;
    config[Parameter.BACKLOG] = 131072;
    config[Parameter.KEEP_ALIVE_TIMEOUT] = dur!"seconds"(60);
    
    config[Parameter.TCP_REUSEPORT] = true;
    config[Parameter.TCP_REUSEADDR] = true;
    config[Parameter.TCP_NODELAY] = true;
    config[Parameter.TCP_LINGER] = true;

    config[Parameter.MAX_REQUEST] = 1_000_000u;
    config[Parameter.MAX_HEADER] = 100;
    config[Parameter.MAX_REQUEST_SIZE] = 1000000;
    config[Parameter.SERVER_STRING] = "dhttpd";
    config[Parameter.INSTALL_DIR] = installDir();
    config[Parameter.ROOT_DIR] = installDir();
    config[Parameter.BAD_REQUEST_FILE] = installDir() ~ "/public/400.html";
    config[Parameter.NOT_FOUND_FILE] = installDir() ~ "/public/404.html";
    config[Parameter.NOT_ALLOWED_FILE] = installDir() ~ "/public/405.html";
    /*
    foreach(key, value ; config)
    {
        log.info(key, " : ", value.toString());
    }
    */
    auto mainDir = new Directory("/public", "index.html", config);
    auto mainRoute = new Route("^/main", mainDir);
    
    auto mainHost = new VirtualHost(["www.dhttpd.fr", "www.dhttpd.com"], [mainRoute]);
    auto mainVirtualHostConfig = new VirtualHostConfig([mainHost], mainHost);
    
    if(nbThreads == 1)
    {
        auto mainServer = new Server(LibevLoop.defaultLoop(), ["0.0.0.0"], [8080], mainVirtualHostConfig, config);
        LibevLoop.runDefaultLoop();
    }
    else if(nbThreads <= totalCPUs)
    {
        ThreadGroup workers = new ThreadGroup();
        foreach(threadIndex ; 0..nbThreads)
        {
            log.trace("New thread ", threadIndex);
            auto worker = new ServerWorker(["0.0.0.0"], [8080], mainVirtualHostConfig, config);
            worker.start();
            workers.add(worker);
        }

        LibevLoop.runDefaultLoop();
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
        uint nbProcesses = 0;
        uint nbThreads = 1;

        getopt(
            args,
            "processes|p",  &nbProcesses,
            "threads|t",    &nbThreads,
        );

        if(!nbProcesses)
        {
            // we are in child process
            start(nbThreads);
        }
        else if(nbProcesses <= totalCPUs)
        {
            Pid[] processes;
            // we are in the master process
            foreach(processIndex ; 0..nbProcesses)
            {
                auto process = spawnProcess([thisExePath()," -t " ~ to!string(nbThreads)]);
                processes ~= process;
                log.info("Process created ", processIndex, " with ID : ", process.processID);
            }

            writeln("Press ENTER to end all processes");
            stdin.readln();

            foreach(process; processes)
            {
                kill(process, SIGINT);
                log.info("Process ", process.processID, " ended with code : ", wait(process));
            }
        }
        else
        {
            log.error("Invalid process count (1 <= p <= ", totalCPUs, ") ");
        }
    }
    catch (SocketOSException e)
    {
        log.fatal(e);
        return -1;
    }
    catch(Exception e)
    {
        log.fatal(e);
        return -1;
    }
    return 0;
}

/*
    auto zmqLoop = new ZmqLoop();
    auto workerHandler = new Worker(zmqLoop.context(), "tcp://127.0.0.1:9999", "tcp://127.0.0.1:9998");
    auto proxyHandler = new Proxy();
    auto workerRoute = new Route("^/worker", workerHandler);
    auto proxyRoute = new Route("^/proxy", proxyHandler);

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
