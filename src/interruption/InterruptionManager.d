module interruption.InterruptionManager;
import http.server.Server;
import core.stdc.signal;

class InterruptionManager
{
    static Server[] servers;
    
    this(Server[] servers)
    {
        this.servers = servers;
        installHandler();
    }
    
    @system nothrow extern(C)
    private static
    void interruptHandler(int)
    {
        if(servers !is null )
        {
            foreach(server; servers)
            {
                server.interrupt();
            }
        }
    }
    
    static void installHandler()
    {
        signal(SIGINT, &interruptHandler);
    }
}
