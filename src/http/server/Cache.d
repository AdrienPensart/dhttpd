module http.server.Cache;

public import http.protocol.Transaction;
public import std.uuid;

class Cache (T)
{
	T[UUID] backend;
	
	this(bool a_enabled=true)
	{
		m_enabled = a_enabled;
	}

	auto length()
	{
		return backend.length;
	}

	bool exists(UUID uuid)
	{
		if(!m_enabled)
		{
			return false;
		}
		return (uuid in backend) !is null;
	}

	auto get(UUID uuid)
	{
		return backend[uuid];
	}

	auto add(UUID uuid, T data)
	{
		backend[uuid] = data;
	}

	bool m_enabled;
	@property auto enabled()
	{
		return m_enabled;
	}
	@property auto enabled(bool a_enabled)
	{
		return m_enabled = a_enabled;
	}
}

alias Cache!(string) FileCache;
alias Cache!(Transaction) HttpCache;
