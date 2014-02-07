module http.server.PortListener;

import std.socket;

import dlog.Logger;
import dlog.Tracer;

import http.server.WebsiteListener;

// Port level
class PortListener
{        
    static int defaultBacklog = 10;

    this(ushort[] ports, WebsiteListener[] websites)
    {
        mixin(Tracer);
        this.websites = websites;

        foreach(port ; ports)
        {
            try
            {
                auto listener = new TcpSocket;
                listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
                listener.bind(new InternetAddress(port));
                listener.listen(defaultBacklog);
                listeners ~= listener;
                log.info("Listening on port ", port);
            }
            catch(SocketOSException e)
            {
                log.error("Can't bind to port. ", e.msg);
            }
        }
    }

    auto getListeners()
    {
        return listeners;
    }

    auto getWebsites()
    {
        return websites;
    }

    private:

        WebsiteListener[] websites;
        Socket[] listeners;
}
