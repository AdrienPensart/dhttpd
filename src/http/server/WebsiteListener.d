module http.server.WebsiteListener;

import http.server.LocationListener;

// Host level
class WebsiteListener
{        
    this(string[] hosts, LocationListener[] locations)
    {
        this.hosts = hosts;
        this.locations = locations;
    }
         
    string[] hosts;
    LocationListener[] locations;
}
