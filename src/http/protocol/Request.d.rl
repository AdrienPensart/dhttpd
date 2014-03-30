module http.protocol.Request;

import std.string;
import std.uni;

import dlog.Logger;

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
        setMethod(raw[mark..mark+end]);
        log.trace("Method : ", getMethod());
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
            content = raw;
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
        mixin(Tracer);
        bool added = append(data);
        if(added)
        {
            m_updated = true;
            lengthadded += data.length;
        }
        return added;
    }

    void init()
    {
        %% write init;
    }

    size_t parse()
    {
        mixin(Tracer);

        off = raw.length - lengthadded;
        log.trace("off = ", off);
        char * buffer = cast(char*)raw.ptr;
        char * p = buffer + off;
        char * pe = p + lengthadded;

        %% write exec;

        nread += p - (buffer + off);
        lengthadded = off;
        log.trace("nread = ", nread);
        log.trace("lengthadded = ", lengthadded);
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

    void setMethod(char[] method)
    {
        this.method = cast(Method)method;
    }

    auto getMethod()
    {
        return method;
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
        Method method;

        // parser data
        int cs;
        size_t nread;
        size_t lengthadded;
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
