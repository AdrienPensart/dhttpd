module http.protocol.Message;

import http.protocol.Protocol;
import http.protocol.Header;

import dlog.Logger;

alias string[string] Headers;

mixin template Message()
{
    import core.sys.posix.sys.uio;
    import crunch.Buffer;
    
    //private UUID m_id;
    private bool m_updated;

    private char[] m_raw;
    //private char[4096] m_raw;
    private size_t m_size;
    
    private Headers m_headers;
    private char[] m_content;
    private string m_protocol;
    private iovec[] m_vec;

    @property bool updated()
    {
        return m_updated;
    }
    @property bool updated(bool a_updated)
    {
        return m_updated = a_updated;
    }

    @property auto raw()
    {
        // stack version
        //return m_raw[0..m_size];
        return m_raw;
    }

    bool append(char[] a_raw)
    {
        // stack version
        //m_raw[m_size..m_size+a_raw.length] = a_raw;
        //m_size += a_raw.length;
        m_raw ~= a_raw;
        m_updated = true;
        return true;
    }

    @property auto hash()
    {
        import xxhash;
        return xxhashOf(cast(ubyte[])raw);
    }
    
    @property ref auto vec()
    {
        return m_vec;
    }

    @property ref auto headers()
    {
        return m_headers;
    }
    @property ref auto headers(Headers a_headers)
    {
        m_headers = a_headers;
        m_updated = true;
        return m_headers;
    }
    bool hasHeader(string key, string value)
    {
        mixin(Tracer);
        import std.uni;
        string headerValue = headers.get(key, "");
        return sicmp(value, headerValue) == 0;
    }

    @property auto content(char[] a_content)
    {
        m_content = a_content;
        m_updated = true;
        return m_content;
    }
    @property auto content()
    {
        return m_content;
    }
 
    @property string protocol(string a_protocol)
    {
        mixin(Tracer);
        if(a_protocol == HTTP_1_0 || a_protocol == HTTP_1_1)
        {
            m_protocol = a_protocol;
            return m_protocol;
        }
        return m_protocol = HTTP_DEFAULT;
    }
    @property string protocol()
    {
        return m_protocol;
    }
}
