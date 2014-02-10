#!/usr/bin/rdmd

/*

import HttpParsing;
import std.stdio;

void main()
{
    //auto httpParser = new HttpParser("GET /index.html HTTP/1.1\r\n\r\n");
    auto httpParser = new HttpParser();
    
    httpParser.execute("GET /path/file.html HTTP/1.0\nFrom");
    httpParser.execute(": someuser@jmarshall.com\nUser-Agent: HTTPTool/1.0\n\n");

    httpParser.finish();

    writeln("Request raw : ", httpParser.request);
}


*/

import std.socket : SocketOSException;
import interruption.InterruptionManager;
import interruption.InterruptionException;
import dlog.Logger;
import http.server.Server;
import http.server.Config;

int main()
{
    try
    {
        auto config = new Config;
        auto server = new Server(config);
        auto interruptManager = new InterruptionManager(server);
        server.run();
    }
    catch (InterruptionException e)
    {
        log.info("\n\nInterrupted : ", e.msg, "\n");
    }
    catch (SocketOSException e)
    {
        log.fatal(e);
        return -1;
    }
    return 0;
}

static ~this()
{
    log.printFunctionStats();
}
