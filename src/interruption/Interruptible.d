module interruption.Interruptible;

import core.stdc.errno;
import core.stdc.signal;
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
    }

    bool interrupted()
    {
        return m_interrupted;
    }

    void handleInterruption()
    {
        mixin(Tracer);
        log.trace("interruption : ", m_interrupted, ", signal : ", m_signal, ", errno : ", errno());
        if(errno() == EINTR && m_signal == SIGINT)
        {
            if(interrupted())
            {
                log.trace("=> by user");
                throw new UserInterruption();
            }
        }
        else
        {
            if(interrupted())
            {
                log.trace("=> by OTHER");
                m_interrupted = false;
                m_signal = -1;
            }
        }
    }
}
