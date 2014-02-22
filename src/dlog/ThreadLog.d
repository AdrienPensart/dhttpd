module dlog.ThreadLog;

import core.time;
import std.array;
import std.string;

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
	
	auto getName()
	{
		return name;
	}

	auto push(string functionName)
	{
		callStack ~= functionName;
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

	string stack()
    {
        return join(callStack, ":");
    }

    auto getDuration()
    {
    	return duration;
    }
}
