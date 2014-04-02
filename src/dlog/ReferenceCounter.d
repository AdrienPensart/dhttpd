module dlog.ReferenceCounter;
import dlog.Logger;
import core.sync.mutex;

// per thread reference counter
class ReferenceCounter(T)
{
	//version(autoprofile)
	//{
	/*
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
	*/
	//}
	
	/*
		import core.atomic;
		this()
		{
			atomicOp!("+=", ulong, int)(m_alive, 1);
		}

		~this()
		{
			atomicOp!("-=", ulong, int)(m_alive, 1);
		}
	*/

	this()
	{
		m_alive++;
	}

	~this()
	{
		m_alive--;
	}

	static bool changed()
	{
		return m_alive != m_alive_show;
	}

	static ulong getAlivedNumber()
	{
		return m_alive_show = m_alive;
	}

	static ulong m_alive = 0;
	static ulong m_alive_show = 0;
}
