import std.stdio;
import std.datetime;
import std.functional;
import std.traits;

template Tracer(string returnType, string functionName, string functionBody)
{
	version(assert)
	{
    	const char [] Tracer =   "TickDuration " ~ functionName ~ "_duration;"
    				    		~ returnType ~ " " ~ functionName ~ " ()"
		    				    "{"
		    				        "StopWatch sw;"
		    				  	    "sw.start();"
		    				  	    "scope(exit) " ~ functionName ~ "_duration = sw.peek();"
		    				  	    "{"
		    				  			~ functionBody ~
		    				  		"}"
		    				    "}";
	}
	else
	{
		const char [] Tracer =  returnType ~ " " ~ functionName ~ " () { " ~ functionBody ~ " } ";
	}
}

mixin (Tracer!("auto", "test", q{ { writeln("in test"); return 234;} } ));


void main()
{
	test();

	version(assert)
	{
		writeln(test_duration);
	}
}
