module http.protocol.Status;

import std.string;
import std.regex;
import std.format;
import std.array;
import dlog.Logger;

enum Status
{
    // 1xx
    Continue = 100,
    SwitchProtocol = 101,
    // 2xx
    Ok = 200,
    Created = 201,
    Accepted = 202,
    NonAuthoritative = 203,
    NoContent = 204,
    ResetContent = 205,
    PartialContent = 206,
    // 3xx
    MultipleChoices = 300,
    MovedPerm = 301,
    Found = 302,
    SeeOther = 303,
    NotModified = 304,
    UseProxy = 305,
    TempRedirect = 307,
    // 4xx
    BadRequest  = 400,
    Unauthorized = 401,
    Payment = 402,
    Forbidden = 403,
    NotFound = 404,
    NotAllowed = 405,
    NotAcceptable = 406,
    ProxyAutg = 407,
    TimeOut = 408,
    Conflict = 409,
    Gone = 410,
    LengthRequired = 411,
    PrecondFailed = 412,
    RequestEntityTooLarge = 413,
    RequestUriTooLarge = 414,
    UnsupportedMediaType = 415,
    RequestedRangeNotSatisfiable = 416,
    ExpectationFailed = 417,
    // 5xx
    InternalError = 500,
    NotImplemented = 501,
    BadGateway = 502,
    ServiceUnavailable = 503,
    GatewayTimeOut = 504,
    UnsupportedVersion = 505
}

bool isError(Status status)
{
    return status >= 500 && status <= 599;
}

string toReason(Status status)
{
    auto writer = appender!string();
    formattedWrite(writer, "%s", status);
    string insertSpace(Captures!(string) m)
    {
        return " " ~ m.hit;
    }
    return strip(replaceAll!(insertSpace)(writer.data, regex("[A-Z]")));
}

unittest
{
    assert(toReason(Status.NotFound) == "Not Found", "Bad transition from status code to reason phrase");
    assert(toReason(Status.BadRequest) == "Bad Request", "Bad transition from status code to reason phrase");
}

/*
enum Status : string
{
    // 1xx
    Continue = "100",
    SwitchProtocol = "101",
    // 2xx
    Ok = "200",
    Created = "201",
    Accepted = "202",
    NonAuthoritative = "203",
    NoContent = "204",
    ResetContent = "205",
    PartialContent = "206",
    // 3xx
    MultipleChoices = "300",
    MovedPerm = "301",
    Found = "302",
    SeeOther = "303",
    NotModified = "304",
    UseProxy = "305",
    TempRedirect = "307",
    // 4xx
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
    // 5xx
    InternalError = "500",
    NotImplemented = "501",
    BadGateway = "502",
    ServiceUnavailable = "503",
    GatewayTimeOut = "504",
    UnsupportedVersion = "505"
}
*/