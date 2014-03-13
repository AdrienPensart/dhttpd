module utils;

import std.parallelism : totalCPUs;
import std.path : dirName;
import std.file;

auto installDir()
{
    return dirName(thisExePath());
}

auto availableCores()
{
	return totalCPUs;
}
