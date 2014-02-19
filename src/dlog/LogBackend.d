module dlog.LogBackend;

import std.stdio;
import std.socket;
import std.conv;
import std.net.curl;

import dlog.Message;
import dlog.MessageFormater;

class FailedRegistering : Exception
{
    this(string msg="Registering of log backend failed.", string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

abstract class LogBackend
{
    this()
    {
        formater = new LineMessageFormater;
    }

    this(MessageFormater formater)
    {
        this.formater = formater;
    }

    auto getFormater()
    {
       return formater;
    }

    void log(Message);
    
    private MessageFormater formater;
}

class FileLogger : LogBackend
{
    this(File file, MessageFormater formater)
	{
        this(formater);
	    this.file = file;
    }	
    
    this(string filepath, MessageFormater formater)
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
	    output().writeln(getFormater.format(lm));
    }
    
    File output()
	{
	    return file;
    }
    	
    private	File file;    
}

class ConsoleLogger : FileLogger
{
    enum Type { OUT, ERR, DEFAULT = OUT};

    this()
    {
        this(Type.DEFAULT, new LineMessageFormater);
    }

    this(MessageFormater formater = new LineMessageFormater, Type type = Type.DEFAULT)
    {
        super(type == Type.OUT ? stdout : stderr, formater);
    }

  	this(Type type = Type.DEFAULT, MessageFormater formater = new LineMessageFormater)
  	{
   	    super(type == Type.OUT ? stdout : stderr, formater);
    }
}

class TcpLogger : LogBackend
{       
    this(string host, ushort port)
    {
        try
        {
            client = new TcpSocket(new InternetAddress(host, port));
        }
        catch(SocketException e)
        {
            throw new FailedRegistering("Can't register TCP log backend server at " ~ host ~ ":" ~ to!string(port) ~ " cause of " ~ e.msg);
        }
    }

    override void log(Message m)
    {
        if(client !is null)
        {
            if(client.isAlive())
            {
                client.send(getFormater().format(m));
            }
        }
    }

    private Socket client;
}

class UdpLogger : LogBackend
{
    this(string host, ushort port)
    {
        address = new InternetAddress(host,port);
        client = new UdpSocket;
    }

    override void log(Message m)
    {
        client.sendTo(getFormater().format(m), address);
    }

    private:

        Socket client;
        Address address;
}

class SmtpLogger : LogBackend
{        
    this(SMTP smtp, uint flushLimit=1)
    {
        this.flushLimit = flushLimit;
        this.smtp = smtp;
    }

    override void log(Message m)
    {
        try
        {
            messageBuffer ~= m;
            if(messageBuffer.length >= flushLimit)
            {
                string messageAccumulator;
                foreach(message ; messageBuffer)
                {
                    string current = getFormater().format(m);
                    messageAccumulator ~= (current ~ "\n");
                }
                smtp.message = messageAccumulator;
                //writeln("Flushing SMTP Logger : ",messageAccumulator);
                smtp.perform();
                messageBuffer.length = 0;
            }
        }
        catch(Exception e)
        {
            writeln("Unable to send email : ",e.msg);
        }
    }
    
    private:
    
        SMTP smtp;
        const uint flushLimit;
        Message[] messageBuffer;
}

class SqlLogger : LogBackend
{        
    override void log(Message)
    {
    }
}

class SnmpLogger : LogBackend
{
    this(string endpoint)
  	{
   	}
    	
   	override void log(Message)
    {
    }
}

class SyslogLogger : LogBackend
{
    this(string endpoint)
   	{
   	}
    	
   	override void log(Message)
    {
    }
}

class ZeromqLogger : LogBackend
{
    this(string endpoint)
  	{
   	}
    	
   	override void log(Message)
    {
    }
}

