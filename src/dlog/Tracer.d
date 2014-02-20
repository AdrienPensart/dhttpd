module dlog.Tracer;

public import std.traits : fullyQualifiedName;

// RAII Tracer
auto Tracer()
{
    string code;
    //version(assert)
    {
        code ~= 
        q{
            enum __marker__;

            const auto __context__ = __traits(identifier, (__traits(parent,__marker__)));
            // we are in a class method, extract Class.Method
            static if(__traits(compiles,this))
            {
                const auto __context2__ = typeof(this).stringof ~ "." ~ __context__;
            }
            static if(__traits(compiles,__context2__))
            {
                //scope __tracer__ = new FunctionLog (__context2__, __context2__);
                FunctionLog __tracer__ = FunctionLog(__context2__, __context2__);
            }
            // we are in a normal function, extract Function name
            else
            {
                //scope __tracer__ = new FunctionLog (__context__, fullyQualifiedName!(__traits(parent,__marker__)));
                FunctionLog __tracer__ = FunctionLog(__context__, fullyQualifiedName!(__traits(parent,__marker__)));
            }

            scope(exit) __tracer__.ended();
        };
    }
    return code;
}
