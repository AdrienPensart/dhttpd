module http.protocol.Response;

import http.protocol.Status;
import http.protocol.Version;

class Response
{
    Status status;
    Version protocolVersion;
    string reason;
    string[string] headers;
}



