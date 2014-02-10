module http.protocol.Request;

import std.string;

import dlog.Logger;

import http.protocol.Version;
import http.protocol.Method;
import http.protocol.RequestHeader;
import http.protocol.Header;

enum MAX_HEADER_SIZE = 80*1024;

class Request
{
    void setMethod(string method)
    {
        this.method = cast(Method)method;
    }

    Method getMethod()
    {
        return method;
    }

    void setVersion(string httpVersion)
    {
        this.httpVersion = cast(Version)httpVersion;
    }

    Version getVersion()
    {
        return httpVersion;
    }

// parsed request
    string content;
    string[string] headers;
    string query;
    string fragment;
    string uri;
    string path;

private:
    Version httpVersion;
    Method method;    
}
