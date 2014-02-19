module http.protocol.Message;

import std.uuid;

import http.protocol.Protocol;
import http.protocol.Header;

class Message
{
    UUID id;
    Protocol protocol;
    string[string] headers;
    string content;

    this()
    {
        id = randomUUID();
    }

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
