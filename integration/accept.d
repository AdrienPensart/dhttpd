import std.stdio;
import std.socket;
import core.stdc.errno;

void main()
{
    try
    {
        auto listener = new TcpSocket;                    
        listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
        /*
        Linger l;
        l.on = 1;
        l.time = 1;
        listener.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, l);
        listener.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
        */
        listener.bind(new InternetAddress(8080));                   
        listener.listen(10);                
        listener.blocking = false;
        
        auto acceptedSocket = listener.accept();
        acceptedSocket.blocking = false;
    }
    catch(Exception e)
    {
        writeln(e);
        writeln(lastSocketError());
        writeln("errno = ", errno);
    }
}

