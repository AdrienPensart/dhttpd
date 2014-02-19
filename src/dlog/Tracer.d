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
            enum __marker{EMPTY};

            const auto __context = __traits(identifier, (__traits(parent,__marker)));
            // we are in a class method, extract Class.Method
            static if(__traits(compiles,this))
            {
                const auto __context2 = typeof(this).stringof ~ "." ~ __context;
            }
            static if(__traits(compiles,__context2))
            {
                auto __tracer_ = new FunctionLog (__context2, __context2);
            }
            // we are in a normal function, extract Function name
            else
            {
                auto __tracer_ = new FunctionLog (__context, fullyQualifiedName!(__traits(parent,__marker)));
            }

            scope(exit) __tracer_.ended();
        };
    }
    return code;
}
