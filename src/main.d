#!/usr/bin/rdmd

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

