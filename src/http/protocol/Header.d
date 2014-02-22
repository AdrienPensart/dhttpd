module http.protocol.Header;

alias string Header;

immutable Header 
    KeepAlive = "keep-alive",
    Close = "close",

    // entity headers
    Allow = "allow",
    ContentEncoding = "content-encoding",
    ContentLanguage = "content-language",
    ContentLength = "content-length",
    ContentLocation = "content-location",
    ContentMD5 = "content-md5",
    ContentRange = "content-range",
    ContentType = "content-type",
    Expires = "expires",
    LastModified = "last-modified",
    // extension-header

    // request/response headers
    CacheControl = "cache-control",
    FieldConnection = "connection",
    FieldDate = "date",
    Pragma = "pragma",
    Trailer = "trailer",
    TransferEncoding = "transfer-encoding",
    Upgrade = "upgrade",
    Via = "via",
    Warning = "warning",

    // request header
    FieldHost = "host",
    UserAgent = "user-agent",
    AcceptEncoding = "accept-encoding",
    AcceptCharset = "accept-charset",
    Accept = "accept",
    AcceptLanguage = "accept-language",
    Authorization = "authorization",
    From = "from",
    IfModifiedSince = "if-modified-since",
    IfMatch = "if-match",
    IfNoneMatch = "if-none-match",
    IfRange = "if-range",
    IfUnmodifiedSince = "if-unmodified-since",
    MaxForwards = "max-forwards",
    ProxyAuthorization = "proxy-authorization",
    Range = "range",
    Referer = "referer",
    DNT = "dnt",

    // response header
    AcceptRanges = "accept-ranges",
    Age = "age",
    ETag = "etag",
    Location = "location",
    ProxyAuthenticate = "proxy-authenticate",
    RetryAfter = "retry-after",
    FieldServer = "server",
    Vary = "vary",
    WWWAuthenticate = "www-authenticate"
;
