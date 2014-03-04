module crunch.AliveReference;
import dlog.Logger;

abstract class AliveReference (T)
{
	static ulong m_alive = 0;
	static ulong m_alive_show = -1;

	this()
	{
		m_alive++;
	}

	~this()
	{
		m_alive--;
	}

	static auto livingReferences()
	{
		return m_alive;
	}

	static void showReferences()
	{
		if(m_alive != m_alive_show)
        {
            m_alive_show = m_alive;
            log.statistic(T.stringof, " alive : ", m_alive_show);
        }
	}
}
