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

    bool hasHeader(Header header, string value)
    {
        string headerValue = headers.get(header, "");
        return value == headerValue;
    }

    bool hasHostHeader()
    {
        return headers.get(Header.Host, "not present") != "not present";
    }
}
