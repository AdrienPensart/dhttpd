module http.protocol.Date;

import std.datetime;
import std.format;
import std.array;
import dlog.Logger;

string[ubyte] days;
string[ubyte] months;

static this()
{
    days[0] = "Sun";
    days[1] = "Mon";
    days[2] = "Tue";
    days[3] = "Wed";
    days[4] = "Thu";
    days[5] = "Fri";
    days[6] = "Sat";

    months[1] = "Jan";
    months[2] = "Feb";
    months[3] = "Mar";
    months[4] = "Apr";
    months[5] = "May";
    months[6] = "Jun";
    months[7] = "Jul";
    months[8] = "Aug";
    months[9] = "Sep";
    months[10] = "Oct";
    months[11] = "Nov";
    months[12] = "Dec";
}

string getDateRFC1123()
{
    mixin(Tracer);
    auto now = Clock.currTime(TimeZone.getTimeZone("Etc/GMT+0"));
    return toDateRFC1123(now);
}

private string toDateRFC1123(SysTime now)
{
    auto writer = appender!string();
    enum rfc1123_format = "%s, %s %s %s %.02d:%.02d:%.02d GMT";
    formattedWrite(writer,
                   rfc1123_format, 
                   days[now.dayOfWeek()], 
                   now.day(), 
                   months[now.month()], 
                   now.year(), 
                   now.hour(), now.minute(), now.second());
    return writer.data;
}

unittest
{
    assert("Wed, 02 Oct 2002 08:00:00 GMT", toDateRFC1123(SysTime(DateTime(2002, 10, 02, 8, 0, 0), UTC())));
}
