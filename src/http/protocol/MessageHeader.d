module http.protocol.MessageHeader;

import dlog.Logger;

mixin template MessageHeader()
{
    import http.protocol.Version;
    import core.sys.posix.sys.uio;
    import std.uuid;
    import crunch.Buffer;
    alias Buffer!(char, 4096) MessageBuffer;
    alias string[string] Headers;

    private
    {
        UUID m_id;
        bool m_updated;
        MessageBuffer m_raw;
        Headers m_headers;
        string m_protocol;
        string[string] cookies;
    }

    @property UUID id()
    {
        return m_id;
    }

    @property bool updated()
    {
        return m_updated;
    }
    @property bool updated(bool a_updated)
    {
        return m_updated = a_updated;
    }

    @property ref auto raw()
    {
        return m_raw;
    }

    @property ref auto raw(MessageBuffer a_raw)
    {
        return m_raw = a_raw;
    }

    bool append(char[] a_raw)
    {
        return m_updated = m_raw.append(a_raw);
    }

    @property auto hash()
    {
        import xxhash;
        return xxhashOf(cast(ubyte[])m_raw[]);
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
