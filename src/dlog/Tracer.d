module dlog.Tracer;

import std.traits : fullyQualifiedName;

// RAII Tracer
auto Tracer()
{
    string __code__;
    version(assert)
    {
        __code__ ~= 
        q{
            enum __marker__;
            auto __context__ = __traits(identifier, (__traits(parent,__marker__)));
            
            // we are in a class method, extract Class.Method
            static if(__traits(compiles,this))
            {
                auto __method__ = typeof(this).stringof ~ "." ~ __context__;
            }
            static if(__traits(compiles,__method__))
            {
                auto __tracer__ = new FunctionLog(__method__, __method__);
                /*
                static if(classdebugs[typeof(this).stringof] == false)
                {
                    pragma(msg, "logging disabled for ", typeof(this).stringof);
                    log.disable();
                }
                */
            }
            // we are in a normal function, extract Function name
            else
            {
                auto __tracer__ = new FunctionLog(__context__, fullyQualifiedName!(__traits(parent,__marker__)));
            }
            //scope(exit) log.enable();
            scope(exit) __tracer__.ended();
        };
    }
    return __code__;
}
