module crunch.Buffer;

import std.traits;
import std.range;
import std.container;
import std.array;

struct Buffer (size_t SIZE, size_t LIMIT, T)
{
	T[SIZE] m_stack;
	
	size_t m_size;
	T[] m_heap;

	bool append(T[] data)
	{
		if(m_size > SIZE)
		{
			if(m_size + data.length <= LIMIT)
			{
				m_heap ~= data;
			}
			else
			{
				return false;
			}
		}
		else
		{
			if(m_size + data.length <= SIZE)
			{
				m_stack[m_size..m_size+data.length] = data;
			}
			else
			{
				return false;
			}
		}
		return true;
	}

	@property T[] data()
	{
		if(m_size <= SIZE)
		{
			return m_stack[0..m_size];
		}
		return m_heap[0..m_size];
	}

	@property size_t length()
	{
		return m_size;
	}
}

unittest
{
	Buffer!(3,6,char) buffer1;
	assert(buffer1.append("12".dup));

	Buffer!(3,6,char) buffer2;
	assert(buffer2.append("12345".dup));

	Buffer!(3,6,char) buffer3;
	assert(!buffer3.append("123456789".dup));
}
