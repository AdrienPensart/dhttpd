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
        string field = raw[field_start..field_start+field_len];
        
        size_t endValue = fpc - buffer - mark;
        string value = raw[mark..mark+endValue];
        field = toLower(field);

        log.trace("Adding header : ", field, " : " , value);
        headers[field] = value;
    }

    action start_value {
        mark = fpc - buffer;
    }
    
    action start_query { 
        query_start = fpc - buffer;
    }
    
    action query_string { 
        size_t end = fpc - buffer - query_start;
        query = raw[query_start..query_start+end];
        log.trace("Query : ", query);
    }
    
    action fragment {
        size_t end = fpc - buffer - mark;
        fragment = raw[mark..mark+end];
        log.trace("Fragment : ", fragment);
    }
    
    action request_method {
        size_t end = fpc - buffer - mark;
        setMethod(raw[mark..mark+end]);
        log.trace("Method : ", getMethod());
    }
    
    action request_uri {
        size_t end = fpc - buffer - mark;
        uri = raw[mark..mark+end];
        log.trace("URI : ", uri);
    }
    
    action http_version {
        size_t end = fpc - buffer - mark;
        // protocol string in validated in grammar
        protocol = raw[mark..mark+end];
        log.trace("Protocol : ", protocol);
    }

    action request_path {
        size_t end = fpc - buffer - mark;
        path = raw[mark..mark+end];
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

class Request : Message
{
    enum Status
    {
        HasError = -1,
        NotFinished = 0,
        Finished = 1
    }

    this()
    {
        %% write init;
    }

    override void feed(char[] data)
    {
        mixin(Tracer);
        log.trace("Feeding request");
        super.feed(data);
        lengthadded += data.length;
    }

    size_t parse()
    {
        mixin(Tracer);
        log.trace("before parsing, raw.length = ", raw.length);
        log.trace("before parsing, lengthadded = ", lengthadded);
        log.trace("before parsing, off = ", off);

        off = raw.length - lengthadded;
        char * buffer = cast(char*)raw.ptr;
        char * p = buffer + off;
        char * pe = p + lengthadded;

        %% write exec;

        nread += p - (buffer + off);
        lengthadded = off;

        log.trace("after parsing, lengthadded = ", lengthadded);
        log.trace("after parsing, off = ", off);
        log.trace("after parsing, nread = ", nread);
        return nread;
    }

    auto getStatus()
    {
        if (hasError())
        {
            //log.test("Has error");
            return Status.HasError;
        }
        else if (isFinished())
        {
            //log.test("Is finished");
            return Status.Finished;
        } 
        else 
        {
            //log.test("Is not finished");
            return Status.NotFinished;
        }
    }

    auto hasError()
    {
        return cs == %%{ write error; }%%;
    }

    auto isFinished()
    {
        return cs >= %%{ write first_final; }%%;
    }

    void setMethod(string method)
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
    Request request = new Request();
    assert(request.getStatus() == Request.Status.NotFinished, "Should NOT be finished if nothing parsed.");
    assert(!request.hasError(), "Should not have an error at the beginning.");
    assert(!request.isFinished(), "Should not be finished since never handed anything.");
}