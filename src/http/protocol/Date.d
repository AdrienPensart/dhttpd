module http.protocol.Date;

import std.datetime;
import std.string : format;
import dlog.Logger;

private immutable string[] days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
private immutable string[] months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
private enum rfc1123_format = "%s, %s %s %s %.02d:%.02d:%.02d GMT";

private TickDuration lastTick;

static this()
{
    lastTick = TickDuration.currSystemTick();
}

bool updateToRFC1123(ref string buffer)
{
    mixin(Tracer);
    auto current = TickDuration.currSystemTick();
    if(current - lastTick > TickDuration(TickDuration.ticksPerSec))
    {
        buffer = nowRFC1123();
        lastTick = current;
        return true;
    }
    // don't update, date didn't changed (1 second precision)
    return false;
}

string nowRFC1123()
{
    mixin(Tracer);
    SysTime now = Clock.currTime(TimeZone.getTimeZone("Etc/GMT+0"));
    return convertToRFC1123(now);
}

string convertToRFC1123(SysTime date)
{
    return format(rfc1123_format, days[date.dayOfWeek()], date.day(), months[date.month()], date.year(), date.hour(), date.minute(), date.second());
}

unittest
{
    assert("Wed, 02 Oct 2002 08:00:00 GMT", convertToRFC1123(SysTime(DateTime(2002, 10, 02, 8, 0, 0), UTC())));
}
