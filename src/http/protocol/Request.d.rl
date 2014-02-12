module http.protocol.Request;

import std.string;

import dlog.Logger;

import http.protocol.Protocol;
import http.protocol.Method;
import http.protocol.RequestHeader;

enum MAX_HEADER_SIZE = 80*1024;

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
        
        headers[field] = value;
        
        log.info("Adding header : ", field, " : " , value);
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
        log.info("Query : ", query);
    }
    
    action fragment {
        size_t end = fpc - buffer - mark;
        fragment = raw[mark..mark+end];
        log.info("Fragment : ", fragment);
    }
    
    action request_method {
        size_t end = fpc - buffer - mark;
        setMethod(raw[mark..mark+end]);
        log.info("Method : ", getMethod());
    }
    
    action request_uri {
        size_t end = fpc - buffer - mark;
        uri = raw[mark..mark+end];
        log.info("URI : ", uri);
    }
    
    action http_version {
        size_t end = fpc - buffer - mark;
        setProtocol(raw[mark..mark+end]);
        log.info("Protocole : ", getProtocol());
    }

    action request_path {
        size_t end = fpc - buffer - mark;
        path = raw[mark..mark+end];
        log.info("Path : ", path);
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
        log.info("Done, content : ", content, ", content.length : ", content.length);
        fbreak;
    }

    include http_parser_grammar "Grammar.rl";

    write data;
}%%

class Request
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

    size_t feed(string data)
    {
        if(!data.length)
            return 0;

        log.info("Data fed : ", data);
        log.info("Data length : ", data.length);

        off = raw.length;
        raw ~= data;
        char * buffer = cast(char*)raw.ptr;

        char * p = buffer + off;
        char * pe = p + data.length;

        %% write exec;

        nread += p - (buffer + off);
        return nread;
    }

    Status getStatus()
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

    bool hasError()
    {
        return cs == %%{ write error; }%%;
    }

    bool isFinished()
    {
        return cs >= %%{ write first_final; }%%;
    }

    void setMethod(string method)
    {
        this.method = cast(Method)method;
    }

    Method getMethod()
    {
        return method;
    }

    void setProtocol(string protocol)
    {
        this.protocol = cast(Protocol)protocol;
    }

    Protocol getProtocol()
    {
        return protocol;
    }

    private:
        // parsed request
        string content;
        string[string] headers;
        string query;
        string fragment;
        string uri;
        string path;
        Protocol protocol;
        Method method;

        // parser data
        int cs;
        size_t nread;
        size_t off;
        long mark;
        long field_start;
        long field_len;
        long query_start;
        long body_start;
        long content_len;
        bool xml_sent;
        bool json_sent;
        string raw;
}

unittest
{
    Request request = new Request();
    assert(request.getStatus() == Request.Status.NotFinished, "Should NOT be finished if nothing parsed.");
    assert(!request.hasError(), "Should not have an error at the beginning.");
    assert(!request.isFinished(), "Should not be finished since never handed anything.");
}
