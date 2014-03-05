module dlog.ReferenceCounter;
import dlog.Logger;

class ReferenceCounter (T)
{
	this()
	{
		m_alive++;
	}

	~this()
	{
		m_alive--;
	}

	static ulong m_alive = 0;
	static ulong m_alive_show = -1;

	static void showReferences()
	{
		if(m_alive != m_alive_show)
	    {
	        m_alive_show = m_alive;
	        log.statistic(T.stringof, " alive : ", m_alive_show);
	    }
	}
}

