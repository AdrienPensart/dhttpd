module dlog.ThreadLog;

import core.time;
import std.array;
import std.string;

import dlog.FunctionLog;

struct ThreadLog
{
	private 
	{
		string m_name;
		FunctionLog[] m_callstack;
		TickDuration m_origin;
		TickDuration m_duration;
		bool m_enabled;
	}
	
	this(string a_name)
	{
		m_name = a_name;
		m_origin = TickDuration.currSystemTick();
		m_enabled = true;
	}
	
	bool enabled()
	{
		return m_enabled;
	}

	void enable()
	{
		m_enabled = true;
	}

	void disable()
	{
		m_enabled = false;
	}

	@property auto name()
	{
		return m_name;
	}

	@property auto duration()
    {
    	return m_duration;
    }

	auto push(FunctionLog functionLog)
	{
		m_callstack ~= functionLog;
	}

	auto pop()
	{
		// we exit last function of the thread, time to compute thread duration
		if(m_callstack.length == 1)
		{
			m_duration = TickDuration.currSystemTick() - m_origin;
		}

		if(m_callstack.length)
		{
			m_callstack.popBack();
		}
	}

	string stack()
    {
        string s;
        foreach(functionLog ; m_callstack)
        {
        	s ~= functionLog.name;
        	s ~= ":";
        }
        return s.chop();
    }
}
