module HttpParsing;
import std.stdio;

/*
#define LEN(AT, FPC) (FPC - buffer - parser->AT)
#define MARK(M,FPC) (parser->M = (FPC) - buffer)
#define PTR_TO(F) (buffer + parser->F)
*/

%%{
    machine http;

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
        string field = request[field_start..field_start+field_len];
        
        size_t endValue = fpc - buffer - mark;
        string value = request[mark..mark+endValue];
        
        headers[field] = value;
        
        writeln("adding header : ", field, " <=> " , value);
    }

    action start_value {
        mark = fpc - buffer;
    }
    
    action start_query { 
        query_start = fpc - buffer;
    }
    
    action query_string { 
        size_t end = fpc - buffer - query_start;
        queryString = request[query_start..query_start+end];
        writeln("query string : ", queryString);
    }
    
    action fragment {
        size_t end = fpc - buffer - mark;
        fragment = request[mark..mark+end];
        writeln("fragment : ", fragment);
    }
    
    action request_method {
        size_t end = fpc - buffer - mark;
        method = request[mark..mark+end];
        writeln("request method : ", method);
    }
    
    action request_uri {
        size_t end = fpc - buffer - mark;
        uri = request[mark..mark+end];
        writeln("request uri : ", uri);
    }
    
    action http_version {
        size_t end = fpc - buffer - mark;
        httpVersion = request[mark..mark+end];
        writeln("http version : ", httpVersion);
    }

    action request_path {
        size_t end = fpc - buffer - mark;
        path = request[mark..mark+end];
        writeln("request path : ", path);
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
            content = request;
        }
        else
        {
            content = request[body_start .. body_start + pe - fpc - 1];
        }
        writeln("done, content : ", content, ", content.length : ", content.length);
        fbreak;
    }

    # HTTP Grammar

    # URI description as per RFC 3986.

    CRLF = ( "\r\n" | "\n" ) ;
    sub_delims    = ( "!" | "$" | "&" | "'" | "(" | ")" | "*" | "+" | "," | ";" | "=" ) ;
    gen_delims    = ( ":" | "/" | "?" | "#" | "[" | "]" | "@" ) ;
    reserved      = ( gen_delims | sub_delims ) ;
    unreserved    = ( alpha | digit | "-" | "." | "_" | "~" ) ;
    pct_encoded   = ( "%" xdigit xdigit ) ;
    pchar         = ( unreserved | pct_encoded | sub_delims | ":" | "@" ) ;
    fragment      = ( ( pchar | "/" | "?" )* ) >mark %fragment ;
    query         = ( ( pchar | "/" | "?" )* ) %query_string ;

    # non_zero_length segment without any colon ":" ) ;
    segment_nz_nc = ( ( unreserved | pct_encoded | sub_delims | "@" )+ ) ;
    segment_nz    = ( pchar+ ) ;
    segment       = ( pchar* ) ;
#    path_empty    = ( pchar{0} ) ;
    path_empty    = ( null ) ;
    
    path_rootless = ( segment_nz ( "/" segment )* ) ;
    path_noscheme = ( segment_nz_nc ( "/" segment )* ) ;
    path_absolute = ( "/" ( segment_nz ( "/" segment )* )? ) ;
    path_abempty  = ( ( "/" segment )* ) ;
    path          = ( path_abempty    # begins with "/" or is empty
                    | path_absolute   # begins with "/" but not "//"
                    | path_noscheme   # begins with a non-colon segment
                    | path_rootless   # begins with a segment
                    | path_empty      # zero characters 
                    ) ;
    reg_name      = ( unreserved | pct_encoded | sub_delims )* ;

    dec_octet     = ( digit                 # 0-9
                    | ("1"-"9") digit       # 10-99
                    | "1" digit{2}          # 100-199
                    | "2" ("0"-"4") digit # 200-249
                    | "25" ("0"-"5")      # 250-255 
                    ) ;

    IPv4address   = ( dec_octet "." dec_octet "." dec_octet "." dec_octet ) ;
    h16           = ( xdigit{1,4} ) ;
    ls32          = ( ( h16 ":" h16 ) | IPv4address ) ;
    IPv6address   = (                               6( h16 ":" ) ls32
                    |                          "::" 5( h16 ":" ) ls32
                    | (                 h16 )? "::" 4( h16 ":" ) ls32
                    | ( ( h16 ":" ){1,} h16 )? "::" 3( h16 ":" ) ls32
                    | ( ( h16 ":" ){2,} h16 )? "::" 2( h16 ":" ) ls32
                    | ( ( h16 ":" ){3,} h16 )? "::"    h16 ":"   ls32
                    | ( ( h16 ":" ){4,} h16 )? "::"              ls32
                    | ( ( h16 ":" ){5,} h16 )? "::"              h16
                    | ( ( h16 ":" ){6,} h16 )? "::" ) ;

    IPvFuture     = ( "v" xdigit+ "." ( unreserved | sub_delims | ":" )+ ) ;
    IP_literal    = ( "[" ( IPv6address | IPvFuture  ) "]" ) ;
    port          = ( digit* ) ;
    host          = ( IP_literal | IPv4address | reg_name ) ;
    userinfo      = ( ( unreserved | pct_encoded | sub_delims | ":" )* ) ;
    authority     = ( ( userinfo "@" )? host ( ":" port )? ) ;
    scheme        = ( alpha ( alpha | digit | "+" | "-" | "." )* ) ;
    relative_part = ( "//" authority path_abempty | path_absolute | path_noscheme | path_empty ) ;
    hier_part     = ( "//" authority path_abempty | path_absolute | path_rootless | path_empty ) ;
    absolute_URI  = ( scheme ":" hier_part ( "?" query )? ) ;

    relative_ref  = ( (relative_part %request_path ( "?" %start_query query )?) >mark %request_uri ( "#" fragment )? ) ;
    URI           = ( scheme ":" (hier_part  %request_path ( "?" %start_query query )?) >mark %request_uri ( "#" fragment )? ) ;
    URI_reference = ( URI | relative_ref ) ;
    
    Method = ( upper | digit ){1,20} >mark %request_method;
    
    http_number  = ( "1." ("0" | "1") ) ;
    HTTP_Version = ( "HTTP/" http_number ) >mark %http_version ;
    
    RequestLine = ( Method " " URI_reference " " HTTP_Version CRLF ) ;
    
    HTTP_CTL = (0 - 31) | 127 ;
    HTTP_separator = ( "(" | ")" | "<" | ">" | "@"
                     | "," | ";" | ":" | "\\" | "\""
                     | "/" | "[" | "]" | "?" | "="
                     | "{" | "}" | " " | "\t" ) ;
    lws = CRLF? (" " | "\t")+ ;
    token = ascii -- ( HTTP_CTL | HTTP_separator ) ;
    content = ((any -- HTTP_CTL) | lws);
    field_name = ( token )+ >start_field %write_field;
    field_value = content* >start_value %write_value;
    MessageHeader = field_name ":" lws* field_value :> CRLF;

    Request = RequestLine ( MessageHeader )* ( CRLF );
    SocketJSONStart = ("@" relative_part);
    SocketJSONData = "{" any* "}" :>> "\0";

    SocketXMLData = ("<" [a-z0-9A-Z\-.]+) >mark %request_path ("/" | space | ">") any* ">" :>> "\0";

    SocketJSON = SocketJSONStart >mark %request_path " " SocketJSONData >mark @json;
    SocketXML = SocketXMLData @xml;

    SocketRequest = (SocketXML | SocketJSON);

    main := (Request | SocketRequest) @done;

}%%

%% write data;

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
    
    // raw request
    public string request;

    // parsed request
    string content;
    string[string] headers;
    string queryString;
    string fragment;
    string method;
    string uri;
    string path;
    string httpVersion;
    
    this()
    {
        %% write init;
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

    size_t execute(string data)
    {
        if(!data.length)
            return 0;

        writeln("Data fed : ", data);
        writeln("Data length : ", data.length);

        off = request.length;
        request ~= data;
        char * buffer = cast(char*)request.ptr;

        char * p = buffer + off;
        char * pe = p + data.length;

        %% write exec;

        nread += p - (buffer + off);
        return nread;
    }

    int finish()
    {
        if (hasError())
        {
            writeln("Has error");
            return -1;
        }
        else if (isFinished())
        {
            writeln("Is finished");
            return 1;
        } 
        else 
        {
            writeln("Is not finished");
            return 0;
        }
    }

    int hasError()
    {
        return cs == %%{ write error; }%%;
    }

    int isFinished()
    {
        return cs >= %%{ write first_final; }%%;
    }
}

