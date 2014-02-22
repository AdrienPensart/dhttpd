module http.server.Cache;

public import http.server.Transaction;
public import std.uuid;

class Cache (T)
{
	T[UUID] backend;

	auto length()
	{
		return backend.length;
	}

	bool exists(UUID uuid)
	{
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
}

alias Cache!(string) FileCache;
alias Cache!(Transaction) HttpCache;
