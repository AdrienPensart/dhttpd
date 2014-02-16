module http.protocol.Header;

enum Header : string
{
    // entity headers
    Allow = "Allow",
    ContentEncoding = "Content-Encoding",
    ContentLanguage = "Content-Language",
    ContentLength = "Content-Length",
    ContentLocation = "Content-Location",
    ContentMD5 = "Content-MD5",
    ContentRange = "Content-Range",
    ContentType = "Content-Type",
    Expires = "Expires",
    LastModified = "Last-Modified",
    // extension-header

    // request/response headers
    CacheControl = "Cache-Control",
    Connection = "Connection",
    Date = "Date",
    Pragma = "Pragma",
    Trailer = "Trailer",
    TransferEncoding = "Transfer-Encoding",
    Upgrade = "Upgrade",
    Via = "Via",
    Warning = "Warning",

    // request header
    Host = "Host",
    UserAgent = "User-Agent",
    AcceptEncoding = "Accept-Encoding",
    AcceptCharset = "Accept-Charset",
    //CacheControl = "Cache-Control",
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
    DNT = "DNT",

    // response header
    AcceptRanges = "Accept-Ranges",
    Age = "Age",
    ETag = "ETag",
    Location = "Location",
    ProxyAuthenticate = "Proxy-Authenticate",
    RetryAfter = "Retry-After",
    Server = "Server",
    Vary = "Vary",
    WWWAuthenticate = "WWW-Authenticate"
}
