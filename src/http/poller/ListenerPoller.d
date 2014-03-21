module http.poller.ListenerPoller;

import dlog.Logger;
import std.socket;
import http.Server;
import deimos.ev;
import core.memory;
import http.Options;
import http.Connection;
import http.poller.ConnectionPoller;

struct ListenerPoller
{
    ev_io io;
    Socket socket;
    Server server;

    this(Server server, InternetAddress address)
    {
        mixin(Tracer);
        
        this.server = server;

        socket = new TcpSocket;
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, server.config.options[Parameter.TCP_REUSEADDR].get!(bool));
        enum REUSEPORT = 15;
        socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption)REUSEPORT, server.config.options[Parameter.TCP_REUSEPORT].get!(bool));
        enum TCP_DEFER_ACCEPT = 9;
        socket.setOption(SocketOptionLevel.TCP, cast(SocketOption)TCP_DEFER_ACCEPT, server.config.options[Parameter.TCP_DEFER].get!(bool));

        socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
        Linger linger;
        linger.on = 1;
        linger.time = 1;
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, linger);

        socket.bind(address);
        socket.blocking = false;
        socket.listen(server.config.options[Parameter.BACKLOG].get!(int));

        ev_io_init(&io, &handleConnection, socket.handle(), EV_READ);
        ev_set_priority (&io, EV_MINPRI);
        ev_io_start(server.loop.loop(), &io);

        GC.addRoot(cast(void*)&this);
        GC.setAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
    }

    private static extern(C) 
    {
        void handleConnection(ev_loop_t *loop, ev_io * watcher, int revents)
        {
            try
            {
                mixin(Tracer);
                auto listenerPoller = cast(ListenerPoller *)watcher;
                if(EV_ERROR & revents)
                {
                    log.error("Listener in error.");
                    return;
                }
                auto listener = listenerPoller.socket;
                auto acceptedSocket = listener.accept();
                log.trace("Handling connection on ", listener.handle(), ", new connection on ", acceptedSocket.handle());

                auto connection = new Connection(acceptedSocket, listenerPoller.server.config);
                auto connectionPoller = new ConnectionPoller(listenerPoller.server, connection);
            }
            catch(Exception e)
            {
                log.error(e);
            }
        }
    }
}
