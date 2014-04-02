module http.protocol.Request;

import std.string;
import std.uni;

import dlog.Logger;

import http.Options;
import http.protocol.Message;
import http.protocol.Protocol;
import http.protocol.Method;
import http.protocol.Header;

%%{
    machine http_parser;

    # Actions
    action mark {
        mark = fpc - buffer;
    }
    
    action start_field {
        field_start = fpc - buffer;
    }
    
    action write_field {
        field_len = fpc - buffer - field_start;
    }

    action write_value {
        auto field = raw[field_start..field_start+field_len];
        
        size_t endValue = fpc - buffer - mark;
        auto value = raw[mark..mark+endValue];
        field = toLower(field);

        log.trace("Header : ", field, " : " , value);
        headers[field.idup] = value.idup;
    }

    action start_value {
        mark = fpc - buffer;
    }
    
    action start_query { 
        query_start = fpc - buffer;
    }
    
    action query_string { 
        size_t end = fpc - buffer - query_start;
        query = raw[query_start..query_start+end].idup;
        log.trace("Query : ", query);
    }
    
    action fragment {
        size_t end = fpc - buffer - mark;
        fragment = raw[mark..mark+end].idup;
        log.trace("Fragment : ", fragment);
    }
    
    action request_method {
        size_t end = fpc - buffer - mark;
        m_method = cast(Method)raw[mark..mark+end];
        switch(m_method)
        {
            case Method.GET:
                raw.limit = options[Parameter.MAX_GET_REQUEST].get!(int);
                break;
            case Method.PUT:
                raw.limit = options[Parameter.MAX_PUT_REQUEST].get!(int);
                break;
            case Method.POST:
                raw.limit = options[Parameter.MAX_POST_REQUEST].get!(int);
                break;
            default:
                break;
        }
        log.trace("Method : ", m_method, ", request limit is now : ", raw.limit);
    }
    
    action request_uri {
        size_t end = fpc - buffer - mark;
        uri = raw[mark..mark+end].idup;
        log.trace("URI : ", uri);
    }
    
    action http_version {
        size_t end = fpc - buffer - mark;
        // protocol string in validated in grammar
        protocol = raw[mark..mark+end].idup;
        log.trace("Protocol : ", protocol);
    }

    action request_path {
        size_t end = fpc - buffer - mark;
        path = raw[mark..mark+end].idup;
        log.trace("Path : ", path);
    }
    
    action xml {
        xml_sent = true;
    }

    action json {
        json_sent = true;
    }
    
    action done {
        body_start = fpc - buffer;
        if(xml_sent || json_sent)
        {
            /*
            content_len = fpc - buffer - body_start + 1;
            */
            content = raw[];
        }
        else
        {
            content = raw[body_start .. body_start + pe - fpc - 1];
        }
        fbreak;
    }

    include http_parser_grammar "Grammar.rl";

    write data;
}%%

struct Request
{
    mixin Message;

    enum Status
    {
        HasError = -1,
        NotFinished = 0,
        Finished = 1
    }

    bool feed(char[] data)
    {
        return m_updated = append(data);;
    }

    void init()
    {
        %% write init;
        raw.init(8192);
    }

    size_t parse(ref Options options)
    {
        mixin(Tracer);

        off = nread;
        log.trace("pre nread = ", nread);
        log.trace("pre off = ", off);
        char * buffer = raw.ptr;
        char * p = raw.ptr + off;
        char * pe = raw.ptr + raw.length;

        //log.trace("Parsing chunk : ", raw[off..raw.length]);
        %% write exec;

        nread += p - (buffer + off);
        log.trace("post nread = ", nread);
        log.trace("post off = ", off);
        return nread;
    }

    @property Status status()
    {
        mixin(Tracer);
        if (hasError())
        {            
            return Status.HasError;
        }
        else if (isFinished())
        {
            return Status.Finished;
        } 
        return Status.NotFinished;
    }

    auto hasError()
    {
        return cs == %%{ write error; }%%;
    }

    auto isFinished()
    {
        return cs >= %%{ write first_final; }%%;
    }

    @property auto method()
    {
        return m_method;
    }

    auto getPath()
    {
        return path;
    }

    auto getUri()
    {
        return uri;
    }

    @property bool keepalive()
    {
        mixin(Tracer);
        log.trace("Protocol for keep alive analysis : ", protocol);
        if(protocol == HTTP_1_0 && hasHeader(FieldConnection, KeepAlive))
        {
            log.trace("HTTP_1_0 and header keep alive present");
            return true;
        }
        else if(protocol == HTTP_1_1 && !hasHeader(FieldConnection, Close))
        {
            log.trace("HTTP_1_1 and header close not present");
            return true;
        }
        log.trace("Connection won't be keep alived");
        return false;
    }

    private:
        // parsed request
        string query;
        string fragment;
        string uri;
        string path;
        Method m_method;

        // parser data
        int cs;
        size_t nread;
        //size_t lengthadded;
        size_t off;
        long mark;
        long field_start;
        long field_len;
        long query_start;
        long body_start;
        long content_len;
        bool xml_sent;
        bool json_sent;
}

unittest
{
    auto request = Request();
    request.init();

    assert(request.status == Request.Status.NotFinished, "Should NOT be finished if nothing parsed.");
    assert(!request.hasError(), "Should not have an error at the beginning.");
    assert(!request.isFinished(), "Should not be finished since never handed anything.");
}
