module interruption.InterruptionException;

class InterruptionException : Exception
{
    this(string msg="User interruption", string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

