import core.thread : Thread;
import std.socket;
import std.regex;
import std.stdio;
import std.random;
import std.conv;

class TcpBurst : core.thread.Thread
{
    this(string host, ushort port)
    {
        super( &run );
        address = new InternetAddress(host, port);
        client = new TcpSocket;
    }

    private:

        void run()
        {
            for(;;)
            {
                writeln("connecting...");
                client.connect(address);
                Thread.sleep(dur!("msecs")(uniform(1, 100)));
                client.shutdown(SocketShutdown.BOTH);
            }
        }
        
        Address address;
        Socket client;
}

void main(string[] args)
{
    if(args.length != 3)
        return;

    string host = args[1];
    ushort port = to!ushort(args[2]);
    
    for(;;)
    {
        core.thread.Thread burst = new TcpBurst(host, port);
        burst.start();
    }
}
