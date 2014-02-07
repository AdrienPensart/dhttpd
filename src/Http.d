import std.stdio;
import std.uri;
import std.string;
import std.traits;

import dlog.Logger;
import Analyzer;

enum { MAX_HEADER_SIZE = 80*1024 }

enum Status : string
{
    Continue = "100",
    SwitchProtocol = "101",
    Ok = "200",
    Created = "201",
    Accepted = "202",
    NonAuthoritative = "203",
    NoContent = "204",
    ResetContent = "205",
    PartialContent = "206",
    MultipleChoices = "300",
    MovedPerm = "301",
    Found = "302",
    SeeOther = "303",
    NotModified = "304",
    UseProxy = "305",
    TempRedirect = "307",
    BadRequest  = "400",
    Unauthorized = "401",
    Payment = "402",
    Forbidden = "403",
    NotFound = "404",
    NotAllowed = "405",
    NotAcceptable = "406",
    ProxyAutg = "407",
    TimeOut = "408",
    Conflict = "409",
    Gone = "410",
    LengthRequired = "411",
    PrecondFailed = "412",
    RequestEntityTooLarge = "413",
    RequestUriTooLarge = "414",
    UnsupportedMediaType = "415",
    RequestedRangeNotSatisfiable = "416",
    ExpectationFailed = "417",
    InternalError = "500",
    NotImplemented = "501",
    BadGateway = "502",
    ServiceUnavailable = "503",
    GatewayTimeOut = "504",
    UnsupportedVersion = "505"
}

enum Method : string
{
    GET = "GET",
    DELETE = "DELETE",
    HEAD = "HEAD",
    POST = "POST",
    PUT = "PUT",
    CONNECT = "CONNECT",
    OPTIONS = "OPTIONS",
    TRACE = "TRACE",
    COPY = "COPY",
    LOCK = "LOCK",
    MKCOL = "MKCOL",
    MOVE = "MOVE",
    PROPFIND = "PROPFIND",
    PROPPATCH = "PROPPATCH",
    SEARCH = "SEARCH",
    UNLOCK = "UNLOCK",
    REPORT = "REPORT",
    MKACTIVITY = "MKACTIVITY",
    CHECKOUT = "CHECKOUT",
    MERGE = "NERGE",
    MSEARCH = "MSEARCH",
    NOTIFY = "NOTIFY",
    SUBSCRIBE = "SUBSCRIBE",
    UNSUBSCRIBE = "UNSUBSCRIBE",
    PATCH = "PATCH",
    PURGE = "PURGE"
}

enum Version : string
{
    HTTP_1_0 = "HTTP/1.0",
    HTTP_1_1 = "HTTP/1.1",
    HTTP_2_0 = "HTTP/2.0"
}

enum Header : string
{
    Host = "Host",
    UserAgent = "User-Agent",
    AcceptEncoding = "Accept-Encoding",
    AcceptCharset = "Accept-Charset",
    CacheControl = "Cache-Control",
    Accept = "Accept",
    AcceptLanguage = "Accept-Language",
    Authorization = "Authorization",
    From = "From",
    IfModifiedSince = "If-Modified-Since",
    IfMatch = "If-Match",
    IfNoneMatch = "If-None-Match",
    IfRange = "If-Range",
    IfUnmodifiedSince = "If-Unmodified-Since",
    MaxForwards = "Max-Forwards",
    ProxyAuthorization = "Proxy-Authorization",
    Range = "Range",
    Referer = "Referer",
    Connection ="Connection",
    Date = "Date",
    Pragma = "Pragma",
    TransferEncoding = "Transfer-Encoding",
    Upgrade = "Upgrade",
    Via = "Via",
    DNT = "DNT"
}

class RequestLine
{
    Method method;
    Version protocolVersion;
    string uri;
   
    bool parse(string rawLine)
    {
        mixin(Tracer);
        auto methodIndex = indexOf(rawLine, ' ');
        if(methodIndex == -1)
        {
            return false;
        }
        auto method = rawLine[0..methodIndex];
        log.info("HTTP Method : ", method);
        foreach(validMethod ; [ EnumMembers!Method ])
        {
            if(method == validMethod)
            {
                method = validMethod;
                break;
            }
        }
        if(!method.length)
        {
            return false;
        }
        auto uriIndex = indexOf(rawLine[methodIndex+1..$], ' ');
        if(uriIndex == -1)
        {
            return false;
        }
        uri = rawLine[methodIndex+1..methodIndex+1+uriIndex];
        if(!uri.length)
        {
            return false;
        }
        log.info("HTTP URI received : '",uri, "'");
        
        const auto startingProtocolVersion = methodIndex+1+uriIndex+1;           
        if(startingProtocolVersion > rawLine.length-2)
        {
            return false;
        }
        auto protocolVersion = rawLine[startingProtocolVersion..$-2];
        foreach(validProtocolVersion ; [ EnumMembers!Version ] )
        {
            if(protocolVersion == validProtocolVersion)
            {
                log.info("HTTP Version received : '",protocolVersion, "'");
                protocolVersion = validProtocolVersion;
                break;
            }
        }
        if(!protocolVersion.length)
        {
            return false;
        }
        return true;
    }
}

class Request
{
    RequestLine rl;
    string[string] headers;
    string message;
    
    this()
    {
        rl = new RequestLine();
    }
    
    bool parse(string raw)
    {
        mixin(Tracer);
        
        log.info("Raw data size : ", raw.length);
        typeof(raw.length) index = 0;

        auto lines = splitLines(raw, KeepTerminator.yes);
        log.info("Raw number of lines : ", lines.length);

        if(lines.length >= 1)
        {
            // parsing the request line (first line of HTTP request)
            if(!rl.parse(lines[0]))
            {
                return false;
            }

            // parse the headers lines
            bool dataDetected = false;
            // Parsing the headers fields and detecting body data
            foreach(line ; lines[1..$])
            {
                log.info("Value of line : '", line, "'");
                // is it a header field, or the null line "\r\n" ?
                if(line.length >= 2)
                {
                    if(line[0] == '\r' && line[1] == '\n')
                    {
                        dataDetected = true;
                        break;
                    }
                }

                auto headerIndex = indexOf(line, ": ");
                if(headerIndex == -1)
                {
                    // it's not a header field, error detected
                    //debug (verbose) writeln("No header field");
                    return false;
                }
                auto header = line[0..headerIndex];
                string headerValue;
                foreach(validHeader ; [ EnumMembers!Header ])
                {
                    if(header == validHeader)
                    {
                        if(headerIndex+2 > line.length-2)
                        {
                            return false;
                        }
                        headerValue = line[headerIndex+2..$-2];
                    }
                }
                // invalid header field
                if(!headerValue.length)
                {
                    return false;
                }
                headers[header] = headerValue;
                log.info("headers[\"",header,"\"] = '", headerValue, "'");
            }
        }
        return true;
    }
}

class Response
{
    Status status;
    Version protocolVersion;
    string reason;
}

