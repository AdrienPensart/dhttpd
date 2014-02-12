module http.server.Host;

import http.server.Route;

class Host
{        
    this(string[] hosts, Route[] routes)
    {
        this.hosts = hosts;
        this.locations = locations;
    }
    
    string[] hosts;
    Route[] locations;
}
