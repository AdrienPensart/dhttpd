module http.protocol.Date;

import std.datetime;
import std.string : format;
import dlog.Logger;

immutable string[] days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
immutable string[] months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
enum rfc1123_format = "%s, %s %s %s %.02d:%.02d:%.02d GMT";

string getDateRFC1123()
{
    mixin(Tracer);
    auto now = Clock.currTime(TimeZone.getTimeZone("Etc/GMT+0"));
    return toDateRFC1123(now);
}

private string toDateRFC1123(SysTime now)
{
    return format(rfc1123_format, days[now.dayOfWeek()], now.day(), months[now.month()], now.year(), now.hour(), now.minute(), now.second());
}

unittest
{
    assert("Wed, 02 Oct 2002 08:00:00 GMT", toDateRFC1123(SysTime(DateTime(2002, 10, 02, 8, 0, 0), UTC())));
}
