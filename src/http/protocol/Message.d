module http.protocol.Message;

import std.uni;

import http.protocol.Protocol;
import http.protocol.Header;

import dlog.Logger;
alias string[string] Headers;

import core.sys.posix.sys.uio;

abstract class Message
{
    this()
    {
        m_updated = false;
    }

    //private UUID m_id;
    private bool m_updated;
    private string m_raw;
    private Headers m_headers;
    private string m_content;
    private Protocol m_protocol;
    private iovec[] m_vec;

    @property bool updated()
    {
        return m_updated;
    }
    @property bool updated(bool a_updated)
    {
        return m_updated = a_updated;
    }

    @property ref string raw()
    {
        return m_raw;
    }
    @property ref string raw(string a_raw)
    {
        m_raw = a_raw;
        m_updated = true;
        return m_raw;
    }
    void feed(char[] data)
    {        
        m_raw ~= data;
        m_updated = true;
    }
    ref string get()
    {
        return raw;
    }
    
    @property ref iovec[] vec()
    {
        return m_vec;
    }

    @property ref Headers headers()
    {
        return m_headers;
    }
    @property ref Headers headers(Headers a_headers)
    {
        m_headers = a_headers;
        m_updated = true;
        return m_headers;
    }
    bool hasHeader(string key, string value)
    {
        string headerValue = headers.get(key, "");
        return sicmp(value, headerValue) == 0;
    }

    @property string content(string a_content)
    {
        m_content = a_content;
        m_updated = true;
        return m_content;
    }
    @property string content()
    {
        return m_content;
    }
 
    @property Protocol protocol(ref Protocol a_protocol)
    {
        if(a_protocol == HTTP_1_0 || a_protocol == HTTP_1_1)
        {
            return m_protocol = a_protocol;
        }
        return m_protocol = HTTP_DEFAULT;
    }
    @property ref Protocol protocol()
    {
        return m_protocol;
    }

    bool keepalive()
    {
        if(protocol == HTTP_1_0 && hasHeader(FieldConnection, KeepAlive))
        {
            return true;
        }
        else if(protocol == HTTP_1_1 && !hasHeader(FieldConnection, Close))
        {
            return true;
        }
        return false;
    }
}
