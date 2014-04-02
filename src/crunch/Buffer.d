module crunch.Buffer;

import dlog.Logger;

// append only buffer
struct Buffer (T, size_t SIZE)
{
    T[SIZE] m_stack;
    T[] m_heap;
    T * m_current;
    size_t m_limit;
    size_t m_length;

    invariant()
    {
        assert(m_length <= m_limit);
        assert(m_current == m_stack.ptr || m_current == m_heap.ptr);
    }

    //alias m_current this;
    void init(size_t a_limit)
    {
        mixin(Tracer);
        limit = a_limit;
        m_length = 0;
        m_current = m_stack.ptr;
    }

    @property size_t limit()
    {
        return m_limit;
    }

    @property size_t limit(size_t a_limit)
    in
    {
        assert(a_limit > SIZE);
    }
    body
    {
        return a_limit > m_length ? m_limit = a_limit : m_limit;
    }

    bool append(T[] data)
    in
    {
        assert(data);
    }
    body
    {
        mixin(Tracer);
        if(m_length + data.length <= SIZE)
        {
            m_stack[m_length..m_length+data.length] = data;
        }
        else if(m_length + data.length <= m_limit)
        {
            if(m_current == m_stack.ptr)
            {
                m_heap.length = 0;
                m_heap ~= m_stack[0..m_length];
            }
            m_heap ~= data;
            m_current = m_heap.ptr;
        }
        else
        {
            return false;
        }
        m_length += data.length;
        return true;
    }

    /*
    T[] opCast()()
    {
        return m_current[0..m_length];
    }
    */

    T[] opSlice()
    {
        return m_current[0..m_length];
    }

    T[] opSlice(size_t x, size_t y)
    in
    {
        assert(x >= 0);
        assert(y <= m_length);
    }
    body
    {
        return m_current[x..y];
    }

    @property T* ptr()
    {
        return m_current;
    }

    @property size_t length()
    {
        return m_length;
    }
}

unittest
{
    auto buffer1 = Buffer!(char,3)(4096);
    assert(buffer1.append("12".dup));

    auto buffer2 = Buffer!(char,3)(4096);
    assert(buffer2.append("12345".dup));

    auto buffer3 = Buffer!(char,3)(6);
    assert(!buffer3.append("123456789".dup));
}
