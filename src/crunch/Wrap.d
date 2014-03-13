module crunch.Wrap;

import std.typecons;
import dlog.Logger;

class Wrap(T)
{
	//mixin T.Constructors;
	
	this(Args...)(Args args)
	{
		base = new T(args);
	}
	
    auto opDispatch(string op, Args...)(Args args)
    {
    	mixin(Tracer);
    	//pragma(msg, __traits(getMember, base, op));
    	return __traits(getMember, base, op)(args);
  	}

  	private T base;
  	mixin Proxy!base;
}
