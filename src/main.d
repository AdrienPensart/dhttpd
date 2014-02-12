#!/usr/bin/rdmd

import std.socket : SocketOSException;
import std.parallelism : totalCPUs;

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
        auto servers = config.getServers();
        auto interruptManager = new InterruptionManager(servers);
        foreach(server; servers)
        {
            server.run();
        }
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
