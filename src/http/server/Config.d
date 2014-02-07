module http.server.Config;

import std.socket;

import dlog.Logger;
import dlog.Tracer;

import http.server.LocationListener;
import http.server.WebsiteListener;
import http.server.PortListener;
import http.server.InterfaceListener;

class Config
{
    LocationListener root;
    WebsiteListener test;
    PortListener ports;
    InterfaceListener interfaces;
    
    this()
    {
        root = new LocationListener("/var/www", "index.html");
        test = new WebsiteListener([""],[root]);
        ports = new PortListener([8080, 8081], [test]);
        interfaces = new InterfaceListener(["0.0.0.0"], [ports]);
    }
    
    Socket[] aggregateListeners()
    {
        mixin(Tracer);
        Socket[] listeners;
        foreach(portListener ; interfaces.getPorts())
        {
            foreach(listener ; portListener.getListeners())
            {
                log.info("Adding listener.");
                listeners ~= listener;
            }
        }
        return listeners;
    }
}
