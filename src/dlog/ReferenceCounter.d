module dlog.ReferenceCounter;
import dlog.Logger;
import core.sync.mutex;

class ReferenceCounter (T)
{
	version(dmdprofiling)
	{
		static Mutex mutex;
		static this()
		{
			mutex = new Mutex();
		}

		this()
		{
			synchronized(mutex)
			{
				m_alive += 1;
			}
		}

		~this()
		{
			synchronized(mutex)
			{
				m_alive -= 1;
			}
		}
	}
	else
	{
		import core.atomic;
		this()
		{
			atomicOp!("+=", ulong, ulong)(m_alive, 1);
		}

		~this()
		{
			atomicOp!("-=", ulong, ulong)(m_alive, 1);
		}
	}

	shared static ulong m_alive = 0;
	shared static ulong m_alive_show = 0;

	shared static void showReferences()
	{
		if(m_alive != m_alive_show)
	    {
	        m_alive_show = m_alive;
	        log.statistic(T.stringof, " alive : ", m_alive_show);
	    }
	}
}

