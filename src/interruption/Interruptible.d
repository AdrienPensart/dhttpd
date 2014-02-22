module interruption.Interruptible;

import core.stdc.errno;
import core.stdc.signal;
import czmq;
import interruption.Exception;
import interruption.Manager;
import dlog.Logger;

abstract class Interruptible
{
    private bool m_interrupted = false;
    private int m_signal = -1;

    this()
    {
        interruption.Manager.addTask(this);
    }

    auto getSignal()
    {
        return m_signal;
    }

    void interrupt(int bySignal) nothrow
    {
        m_signal = bySignal;
        m_interrupted = true;
        zctx_interrupted = true;
    }

    bool interrupted()
    {
        return m_interrupted;
    }

    void handleInterruption()
    {
        mixin(Tracer);
        if(errno() == EINTR && m_signal == SIGINT)
        {
            if(interrupted())
            {
                throw new UserInterruption();
            }
        }
        else
        {
            if(interrupted())
            {
                m_interrupted = false;
                m_signal = -1;
            }
        }
    }
}
