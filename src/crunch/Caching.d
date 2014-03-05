module crunch.Caching;
import dlog.Logger;

struct Cache (Key, Value)
{
	alias Value[Key] Store;

	private bool m_enabled;
	private Store m_store;

	@property auto enabled()
	{
		return m_enabled;
	}
	@property auto enabled(bool a_enabled)
	{
		return m_enabled = a_enabled;
	}

	protected @property ref auto store()
	{
		return m_store;
	}

	protected @property ref auto store(Store a_store)
	{
		return m_store = a_store;
	}
}

// create a global cache for this object
class Cacheable (Key, Value)
{
	Value get()
    {
        if(cache.enabled)
        {
        	Key m_key = key();
        	Value m_value = cache.store.get(m_key, (cache.store[m_key] = value()));
            return m_value;
        }
        return value();
    }

    static void enable_cache(bool enabled)
    {
    	cache.enabled = enabled;
    }

	private static Cache!(Key, Value) cache;

	abstract Key key();
	abstract Value value();
}
