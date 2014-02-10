module http.protocol.Parser;

import http.protocol.Request;
import dlog.Logger;

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
        
        request.headers[field] = value;
        
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
        request.query = raw[query_start..query_start+end];
        log.info("Query : ", request.query);
    }
    
    action fragment {
        size_t end = fpc - buffer - mark;
        request.fragment = raw[mark..mark+end];
        log.info("Fragment : ", request.fragment);
    }
    
    action request_method {
        size_t end = fpc - buffer - mark;
        request.setMethod(raw[mark..mark+end]);
        log.info("Method : ", request.getMethod());
    }
    
    action request_uri {
        size_t end = fpc - buffer - mark;
        request.uri = raw[mark..mark+end];
        log.info("URI : ", request.uri);
    }
    
    action http_version {
        size_t end = fpc - buffer - mark;
        request.setVersion(raw[mark..mark+end]);
        log.info("HTTP Version : ", request.getVersion());
    }

    action request_path {
        size_t end = fpc - buffer - mark;
        request.path = raw[mark..mark+end];
        log.info("Path : ", request.path);
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
            request.content = raw;
        }
        else
        {
            request.content = raw[body_start .. body_start + pe - fpc - 1];
        }
        log.info("Done, content : ", request.content, ", content.length : ", request.content.length);
        fbreak;
    }

    include http_parser_grammar "Grammar.rl";

    write data;
}%%

enum HttpParserStatus
{
    HasError = -1,
    NotFinished = 0,
    Finished = 1
}

class HttpParser
{
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
    Request request;

    this()
    {
        %% write init;
        request = new Request;
    }
    
    unittest
    {
        auto httpParser = new HttpParser();
        int rc = 0;
        rc = httpParser.finish();
        assert(rc == 0, "Should NOT be finished if nothing parsed.");

        rc = httpParser.hasError();
        assert(rc == 0, "Should not have an error at the beginning.");

        rc = httpParser.isFinished();
        assert(rc == 0, "Should not be finished since never handed anything.");
    }

    Request getRequest()
    {
        return request;
    }

    size_t execute(string data)
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

    HttpParserStatus finish()
    {
        if (hasError())
        {
            log.test("Has error");
            return HttpParserStatus.HasError;
        }
        else if (isFinished())
        {
            log.test("Is finished");
            return HttpParserStatus.Finished;
        } 
        else 
        {
            log.test("Is not finished");
            return HttpParserStatus.NotFinished;
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
}

