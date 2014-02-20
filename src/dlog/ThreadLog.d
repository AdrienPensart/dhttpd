module dlog.ThreadLog;

import core.time;
import std.array;

struct ThreadLog
{
	private string name;
	private string[] callStack;
	private TickDuration origin;
	private TickDuration duration;

	this(string name)
	{
		this.name = name;
		this.origin = TickDuration.currSystemTick();
	}

	auto push(string functionName)
	{
		callStack ~= functionName;
	}

	auto getName()
	{
		return name;
	}

	auto pop()
	{
		// we exit last function of the thread, time to compute thread duration
		if(callStack.length == 1)
		{
			duration = TickDuration.currSystemTick() - origin;
		}

		if(callStack.length)
		{
			callStack.popBack();
		}
	}

	auto getStackTrace()
    {
        string st;
        version(assert)
        {
            synchronized
            {
                foreach(index, context ; callStack)
                {
                    st ~= ((index > 0 ? ":" : "") ~ context);
                }
                return st;
            }
        }
        return st;
    }

    auto getDuration()
    {
    	return duration;
    }
}
