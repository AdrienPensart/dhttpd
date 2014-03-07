module dlog.FunctionLog;

import dlog.Logger;
import std.datetime;
import core.sync.mutex;

class FunctionLog
{
    string m_name;
    string m_fullname;
    TickDuration m_duration;

    this(string name, string fullname)
    {
        synchronized(tracerMutex)
        {
            this.m_duration = TickDuration.currSystemTick();
            this.m_name = name;
            this.m_fullname = fullname;
            log.enter(this);
        }
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

    void ended()
    {
        synchronized(tracerMutex)
        {
            m_duration =  TickDuration.currSystemTick() - m_duration;
            log.leave(this);
        }
    }
}
