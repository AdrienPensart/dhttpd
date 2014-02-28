#!/usr/bin/rdmd

import std.c.stdlib;
import std.c.string;

import std.string;
import std.socket;
import std.datetime;
import std.file;
import std.path : dirName;
import std.parallelism : totalCPUs;
import core.thread;

import dlog.Logger;

import http.protocol.Status;

import http.server.Server;
import http.server.Cache;
import http.server.Handler;
import http.server.Directory;
import http.server.Route;
import http.server.VirtualHost;
import http.server.Config;

import czmq;
import libev.ev;
import core.stdc.signal;

extern(C)
{
    static void sigint_cb (ev_loop_t *loop, ev_signal *w, int revents)
    {
        ev_break(loop, EVBREAK_ALL);
    }
}

int main()
{
    mixin(Tracer);
    try
    {
        log.register(new ConsoleLogger);
        auto fileCache = new FileCache();
        auto httpCache = new HttpCache();
        Config config;
        Server[] servers;
        Handler[Status] defaultHandlers;

        int zmqMajor, zmqMinor, zmqPatch;
        zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
        string installDir = dirName(thisExePath());

        int evMajor = ev_version_major();
        int evMinor = ev_version_minor();

        ev_loop_t * loop;
        ev_signal signal_watcher;
        loop = ev_default_loop(EVFLAG_AUTO);
        ev_signal_init (&signal_watcher, &sigint_cb, SIGINT);
        ev_signal_start (loop, &signal_watcher);

        config[Parameter.EV_VERSION] = format("%s.%s", evMajor, evMinor);
        config[Parameter.ZMQ_VERSION] = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
        config[Parameter.FILE_CACHE] = fileCache;
        config[Parameter.HTTP_CACHE] = httpCache;
        config[Parameter.LOGGER] = log;
        config[Parameter.MAX_CONNECTION] = 60;
        config[Parameter.BACKLOG] = 131072;
        config[Parameter.KEEP_ALIVE_TIMEOUT] = dur!"seconds"(5);
        config[Parameter.MAX_REQUEST] = 1_000_000;
        config[Parameter.MAX_HEADER] = 100;
        config[Parameter.MAX_REQUEST_SIZE] = 1000000;
        config[Parameter.SERVER_STRING] = "dhttpd";
        config[Parameter.INSTALL_DIR] = installDir;
        config[Parameter.ROOT_DIR] = installDir;
        config[Parameter.TOTAL_CPU] = totalCPUs;
        config[Parameter.BAD_REQUEST_FILE] = installDir ~ "/public/400.html";
        config[Parameter.NOT_FOUND_FILE] = installDir ~ "/public/404.html";
        config[Parameter.NOT_ALLOWED_FILE] = installDir ~ "/public/405.html";

        foreach(key, value ; config)
        {
            log.info(key, " : ", value.toString());
        }

        auto mainDir = new Directory(config, "/public", "index.html");
        auto mainRoute = new Route("^/main", mainDir);
        auto mainHost = new VirtualHost(["www.dhttpd.fr", "www.dhttpd.com"], [mainRoute]);
        auto mainServer = new Server(loop, ["0.0.0.0"], [8080, 8081, 8082, 8083], [mainHost], mainHost, config);
        servers ~= mainServer;
        
        ev_run(loop, 0);
        
        log.trace("Main ended.");
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
        auto servers = config.getServers();
        auto interruptManager = new InterruptionManager(cast(Interruptible[])servers);
        foreach(server; servers)
        {
            server.run();
        }

        auto mainServer = new Server(["0.0.0.0"], [8080, 8081], [mainHost], mainHost, config);
        servers ~= mainServer;
        */

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
