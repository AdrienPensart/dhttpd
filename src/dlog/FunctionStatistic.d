module dlog.FunctionStatistic;

import core.time;

ulong toTime(TickDuration duration)
{
    return duration.nsecs;
}

struct FunctionStatistic
{
    this(string fullName)
    {
        this.fullName = fullName;
    }

    ulong averageTimePerCall() nothrow
    {
        return totalDuration.nsecs / timesCalled;
    }

    ulong totalTime() nothrow
    {
        return totalDuration.nsecs;
    }

    string fullName;
    ulong timesCalled;
    TickDuration totalDuration;
}

