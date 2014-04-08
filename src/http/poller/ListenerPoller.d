module http.poller.ListenerPoller;

import dlog.Logger;
import deimos.ev;
import crunch.Utils;
import crunch.ManualMemory;
import std.socket;
import http.server.Server;
import http.poller.ConnectionPoller;

struct ListenerPoller
{
    ev_io io;
    Socket socket;
    Server server;
    InternetAddress address;

    mixin ManualMemory;

    this(Server a_server, InternetAddress a_address)
    {
        mixin(Tracer);
        server = a_server;
        address = a_address;
        socket = new TcpSocket;

        configureSocket();
        bindListener();
        
        ev_io_init(&io, &handleConnection, socket.handle(), EV_READ);
        ev_set_priority (&io, EV_MINPRI);
        ev_io_start(server.loop.loop(), &io);

        acquireMemory();
    }

    void release()
    {
        mixin(Tracer);
        log.trace("ListenerPoller released");
        ev_io_stop(server.loop.loop(), &io);
        releaseMemory();
    }

    private void configureSocket()
    {
        mixin(Tracer);
        socket.enableReuseAddr(server.config.options[Parameter.TCP_REUSEADDR].get!(bool));
        socket.enableReusePort(server.config.options[Parameter.TCP_REUSEPORT].get!(bool));
        socket.enableDeferAccept(server.config.options[Parameter.TCP_DEFER].get!(bool));
        socket.setNoDelay(server.config.options[Parameter.TCP_NODELAY].get!(bool));
        socket.setLinger(server.config.options[Parameter.TCP_LINGER].get!(bool));
        log.trace("Set up listener fd : ", socket.handle());
    }

    private void bindListener()
    {
        mixin(Tracer);
        socket.bind(address);
        socket.blocking = false;
        socket.listen(server.config.options[Parameter.BACKLOG].get!(int));
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
