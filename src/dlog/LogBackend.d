module dlog.LogBackend;

import std.stdio;
import std.socket;
import std.conv;

import dlog.Logger;
import dlog.Message;
import dlog.MessageFormater;

import czmq;

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
	    file.writeln(cast(string)getFormater.format(lm));
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

class ZmqLogger : LogBackend
{
    this(string endpoint)
    {
    }
        
    override void log(Message m)
    {
    }
}

class TcpLogger : LogBackend
{       
    this(string host, ushort port, MessageFormater formater = new BinaryMessageFormater)
    {
        super(formater);
        try
        {
            client = new TcpSocket;
            address = new InternetAddress(host, port);
            client.connect(address);
        }
        catch(Exception e)
        {
            .log.error("TcpLogger : Can't register TcpLogger to ", host, ":", port, " : ", e.msg);
            client.close();
        }
    }

    override void log(Message m)
    {
        if(client.isAlive)
        {
            auto data = getFormater().format(m);
            auto datalength = client.send(data);
            if (datalength == Socket.ERROR)
            {
                .log.logging("TcpLogger : Socket error : ", lastSocketError());
                client.close();
            }
            else if(datalength == 0)
            {
                .log.logging("TcpLogger : Disconnection on ", client.handle());
                client.close();
            }
        }
    }

    private Address address;
    private Socket client;
}

class UdpLogger : LogBackend
{
    this(string host, ushort port, MessageFormater formater = new LineMessageFormater)
    {
        super(formater);
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

/*
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

*/
