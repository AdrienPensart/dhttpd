module dlog.FunctionLog;

import dlog.Logger;
import core.time;

struct FunctionLog
{
    struct FunctionStat
    {
        string fullname;
        ulong timesCalled;
        TickDuration totalDuration;

        this(string a_fullname)
        {
            fullname = a_fullname;
        }

        auto averageTime()
        {
            return totalDuration.nsecs / timesCalled;
        }

        auto totalTime() nothrow
        {
            return totalDuration.nsecs;
        }
    }

    static FunctionStat[string] m_stats;

    string m_name;
    string m_fullname;
    TickDuration m_duration;

    this(string a_name, string a_fullname)
    {
        m_duration = TickDuration.currSystemTick();
        m_name = a_name;
        m_fullname = a_fullname;
        log.enter(this);
    }

    bool ended()
    {
        m_duration =  TickDuration.currSystemTick() - m_duration;

        if(!(m_fullname in m_stats))
        {
            m_stats[m_fullname] = FunctionStat(m_fullname);
        }
        m_stats[fullname].totalDuration += m_duration;
        m_stats[fullname].timesCalled += 1;
        log.leave(this);
        return true;
    }

    @property auto name()
    {
        return m_name;
    }

    @property auto fullname()
    {
        return m_fullname;
    }

    @property auto duration()
    {
        return m_duration;
    }
}
