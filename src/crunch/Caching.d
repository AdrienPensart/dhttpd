module crunch.Caching;
import dlog.Logger;

struct Cache (Key, Value)
{
    alias Value[Key] Store;

    private bool m_enabled = true;
    private Store m_store;

    Value get(Key key, Value delegate() value)
    {
        if(m_enabled)
        {
            //Value toReturn = store.get(key, null);
            auto toReturn = key in store;
            if(toReturn)
            {
                log.trace("Cached hit : ", key);
                return *toReturn;
            }
            else
            {
                auto computed = value();
                if(computed !is null)
                {
                    log.trace("Cached : ", key);
                    return store[key] = computed;
                }
                else
                {
                    return null;
                }
            }
        }
        return value();
    }

    void set(Key key, Value value)
    {
        store[key] = value;
    }

    void invalidate(Key key)
    {
        store.remove(key);
    }

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
        return cache.get(key(), value());
    }

    static void enable_cache(bool enabled)
    {
        cache.enabled = enabled;
    }

    private static Cache!(Key, Value) cache;

    abstract Key key();
    abstract Value value();
}
