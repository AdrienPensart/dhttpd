module http.protocol.RequestHeader;

enum RequestHeader : string
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
