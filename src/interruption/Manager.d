module interruption.Manager;

import interruption.Interruptible;
import core.stdc.signal;

private __gshared Interruptible[] tasks;
private __gshared auto signals = [SIGINT];

static this()
{
	foreach(value ; signals)
	{
		signal(SIGINT, &interruptHandler);
	}
}

@system nothrow extern(C)
private void interruptHandler(int signo)
{
    foreach(task; tasks)
    {
        task.interrupt(signo);
    }
}

void addTask(Interruptible task)
{
    tasks ~= task;
}
