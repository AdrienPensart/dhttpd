import core.demangle;
import std.array;
import std.conv;
import std.file;
import std.regex;
import std.stdio;
import std.string;
import std.algorithm;

enum Column {
	NUM_CALLS,
	TREE_TIME,
	TREE_TIME_PERCENT,
	FUNC_TIME,
	FUNC_TIME_PERCENT,
	AVG_FUNC_TIME,
	FUNC_NAME,
	SIZE
}

struct Data {
	long numCalls;
	long treeTime;
	long funcTime;
	long avgFuncTime;
	char[] funcName;
}

void main( string[] args )
{
	string filename;
	switch(args.length)
	{
		case 1:
			filename = "trace.log";
			break;
		default:
			filename = args[1];
			break;
	}

	string file;
	try
	{
		file = readText(filename);
	}
	catch(Exception e)
	{
		writefln( "Can't read " ~ filename ~ "."
		 "\nUsage: " ~ args[0] ~ " [trace file] (default: trace.log)." );
		writeln(e);
		return;
	}

	string[] inputLines = splitLines(file);

	uint lineCounter;
	foreach( uint counter, string contents; inputLines ) {
		if( contents.length > 0 && contents[0] == '=' ) {
			lineCounter = counter;
			break;
		}
	}

	// Extract tick value
	auto ticksPerSecondRegExp = regex("[0-9]+");
	auto m = match(inputLines[lineCounter], ticksPerSecondRegExp);

	long ticksPerSecond = to!long( m.hit );
	writefln( "ticksPerSecond: %d", ticksPerSecond );

	// Skip five lines to the beginning of the data
	lineCounter += 5;
	inputLines = inputLines[lineCounter..$];
	Data[] datas;
	foreach( uint counter, string contents; inputLines )
	{
		auto re = split( inputLines[counter] );
		Data tmp;
		tmp.numCalls = to!long( re[0] );
		tmp.treeTime = to!long( re[1] );
		tmp.funcTime = to!long( re[2] );
		tmp.avgFuncTime = to!long( re[3] );
		tmp.funcName = demangle( join(re[4..$], " ") );
		datas ~= tmp;

		
	}

    sort!((a,b) {return a.funcTime < b.funcTime;})(datas);

    foreach(data; datas)
    {
    	writefln
	    (
	    	"\n%s\n\tnumCalls : %s\n\ttreeTime : %s\n\tfuncTime : %s\n\tavgFuncTime : %s\n", 
	    	data.funcName, data.numCalls, data.treeTime, data.funcTime, data.avgFuncTime
	    );
    }
}
