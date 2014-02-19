module http.server.Cache;

public import std.uuid;


class Cache
{
	alias string[UUID] CacheBackend;
	CacheBackend backend;

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

	auto add(UUID uuid, string data)
	{
		backend[uuid] = data;
	}
}

