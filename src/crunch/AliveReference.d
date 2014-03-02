module crunch.AliveReference;

abstract class AliveReference (T)
{
	static ulong m_alive = 0;

	this()
	{
		m_alive++;
	}

	~this()
	{
		m_alive--;
	}

	static auto alive()
	{
		return m_alive;
	}
}
