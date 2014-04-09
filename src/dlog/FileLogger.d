module dlog.FileLogger;

import dlog.LogBackend;
import dlog.Message;
import dlog.MessageFormater;
import std.stdio;

class FileLogger : LogBackend
{
    this(File file, MessageFormater formater = new LineMessageFormater)
	{
        this(formater);
	    this.file = file;
    }	
    
    this(string filepath, MessageFormater formater = new LineMessageFormater)
	{
        this(formater);
	    file = File(filepath, "a");
    }

    private this(MessageFormater formater)
    {
        super(formater);
    }

	override void log(Message lm)
    {
	    file.writeln(cast(string)formater.format(lm));
    }
	
    private	File file;
}
