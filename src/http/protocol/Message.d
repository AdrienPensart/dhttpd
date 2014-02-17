module http.protocol.Message;

import http.protocol.Protocol;
import http.protocol.Header;

class Message
{
    Protocol protocol;
    string[string] headers;
    string content;

    void setProtocol(string protocol)
    {
        this.protocol = cast(Protocol)protocol;
    }

    auto getProtocol()
    {
        return protocol;
    }

    auto getHeaders()
    {
        return headers;
    }

    auto getHeader(Header header)
    {
        return headers[header];
    }

    bool hasHeader(Header key)
    {
        return (key in headers) !is null;
    }

    bool hasHeader(Header key, string value)
    {
        string headerValue = headers.get(key, "");
        return value == headerValue;
    }
}
