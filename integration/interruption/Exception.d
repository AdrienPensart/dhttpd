module interruption.Exception;

abstract class Interruption : Exception
{
    this(string msg="interruption", string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

final class UserInterruption : Interruption
{
	this(string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null)
    {
        super("user interruption", file, line, next);
    }
}

final class UnknownInterruption : Interruption
{
	this(string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null)
    {
        super("unknown interruption", file, line, next);
    }
}
