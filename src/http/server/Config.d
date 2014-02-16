module http.server.Config;

import std.socket;
import std.file;
import std.path : dirName;
import std.parallelism : totalCPUs;
import core.thread;

import dlog.Logger;

import http.protocol.Status;

import http.server.Handler;
import http.server.Directory;
import http.server.Route;
import http.server.Host;
import http.server.Server;
import http.server.Options;

class Config
{
    this()
    {
        installDir = dirName(thisExePath());
        serverString = DEFAULT_SERVER_HEADER;

        log.info("CPU Count : ", totalCPUs);
        log.info("Server banner : ", serverString);
        log.info("Install dir : ", installDir);

        options[Parameter.MAX_CONNECTION] = Default.MAX_CONNECTION;
        options[Parameter.BACKLOG] = Default.BACKLOG;
        options[Parameter.TIMEOUT] = Default.TIMEOUT;
        options[Parameter.MAX_REQUEST] = Default.MAX_REQUEST;
        options[Parameter.MAX_HEADER] = Default.MAX_HEADER;

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
        
        auto mainDir = new Directory(installDir ~ "/public", "index.html");
        auto mainRoute = new Route("^/main", mainDir);
        auto mainHost = new Host(["www.dhttpd.fr"], [mainRoute]);
        auto mainServer = new Server(["0.0.0.0"], [8080, 8081], [mainHost]);
        servers ~= mainServer;
    }

    auto getServers()
    {
        return servers;
    }

    static auto getInstallDir()
    {
        return installDir;
    }

    static auto getServerString()
    {
        return serverString;
    }

    static auto getOptions()
    {
        return options;
    }

    private:

        //Handler[] handlers;
        //Route[] routes;
        //Directory[] directories;
        //Host[] hosts;
        //Port[] ports;
        //Interface[] interfaces;

        static string installDir;
        static string serverString;
        static Options options;

        string[string] defaultHeaders;
        Server[] servers;
        Handler[Status] defaultHandlers;
}
