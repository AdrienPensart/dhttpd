module interruption.Manager;

import std.stdio;
import interruption.Interruptible;
import core.stdc.signal;
import zsys;

private __gshared Interruptible[] tasks;
private __gshared auto signals = [SIGINT];

static this()
{
	installSignalHandler();
}

@system nothrow extern(C)
private void interruptHandler(int signo)
{
    foreach(task; tasks)
    {
        task.interrupt(signo);
    }
}

void installSignalHandler()
{
	zsys_handler_reset ();
    zsys_handler_set (null);
	foreach(signo ; signals)
	{
		writeln("Interrupt installed on ", signo);
		signal(signo, &interruptHandler);
	}
}

void addTask(Interruptible task)
{
    tasks ~= task;
}
