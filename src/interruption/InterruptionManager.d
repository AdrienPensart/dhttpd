module interruption.InterruptionManager;
import http.server.Server;
import core.stdc.signal;

class InterruptionManager
{
    static Server server;
    
    this(Server server)
    {
        this.server = server;
        installHandler();
    }
    
    @system nothrow extern(C)
    private static
    void interruptHandler(int)
    {
        if(! (server is null) )
        {
            server.interrupt();
        }
    }
    
    static void installHandler()
    {
        signal(SIGINT, &interruptHandler);
    }
}
