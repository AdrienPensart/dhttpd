%%{
    
    machine http_parser_grammar;

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
    
    path_empty    = ( null ) ; # path_empty    = ( pchar{0} ) ;
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
