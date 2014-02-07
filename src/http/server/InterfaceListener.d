module http.server.InterfaceListener;

import http.server.PortListener;

// IP version level dispatcher / Interface dispatcher
class InterfaceListener
{
    this(string[] identifiers, PortListener[] ports)
    {
        this.identifiers = identifiers;
        this.ports = ports;
    }

    auto getPorts()
    {
        return ports;
    }

    private:

       string[] identifiers;
       PortListener[] ports;
}
