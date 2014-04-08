module http.protocol.Entity;

import http.server.Connection;
import dlog.Logger;

interface Entity
{
    bool send(char[] header, Connection connection);
    size_t length();
    bool updated();
    string lastModified();

    final string etag()
    {
        import std.digest.ripemd;
        return ripemd160Of(lastModified()).toHexString.idup;
    }
}
