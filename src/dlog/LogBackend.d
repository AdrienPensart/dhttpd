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
        m_formater = new LineMessageFormater;
    }

    this(MessageFormater a_formater)
    {
        m_formater = a_formater;
    }

    @property auto formater()
    {
       return m_formater;
    }

    bool init()
    {
        return true;
    }

    void log(Message);
    
    private MessageFormater m_formater;
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
	    file.writeln(cast(string)formater.format(lm));
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

// PUB / SUB pattern
class ZmqLogger : LogBackend
{
    /*
    int zmqMajor, zmqMinor, zmqPatch;
    zmq_version(&zmqMajor, &zmqMinor, &zmqPatch);
    string zmqVersion = format("%s.%s.%s", zmqMajor, zmqMinor, zmqPatch);
    .log.logging("ZMQ version : ", zmqVersion);
    */
    
    shared static this()
    {
        zctx  = cast(shared(zctx_t *))zctx_new();
        assert(zctx);
    }

    shared static ~this()
    {
        zctx_destroy(cast(zctx_t **)&zctx);
    }

    this(string endpoint, MessageFormater formater = new BinaryMessageFormater)
    {
        super(formater);
        .log.logging("ZMQ Logger endpoint : ", endpoint);
        import std.string : toStringz;
        pub = zsocket_new (cast(zctx_t *)zctx, ZMQ_PUSH);
        assert(pub);
        auto result = zsocket_connect(pub, toStringz(endpoint));
        assert(result == 0, to!string(zmq_strerror(zmq_errno())));
    }
    
    override void log(Message m)
    {
        void[] data = formater.format(m);
        send(data);
    }

    private void send(void[] data)
    {
        auto msg = zmsg_new();
        assert(msg);
        auto push = zmsg_addmem(msg, data.ptr, data.length);
        assert(push == 0);
        zmsg_send(&msg, pub);
    }

    private:

        void * pub;
        shared static zctx_t * zctx;
}

class TcpLogger : LogBackend
{       
    this(string host, ushort port, MessageFormater formater = new BinaryMessageFormater)
    {
        super(formater);
        address = new InternetAddress(host, port);
    }

    override bool init()
    {
        try
        {
            client = new TcpSocket;
            client.connect(address);
        }
        catch(Exception e)
        {
            .log.error("TcpLogger : Can't register to ", address, " : ", e.msg);
            client.close();
            return false;
        }
        return true;
    }

    override void log(Message m)
    {
        if(client !is null && client.isAlive)
        {
            auto data = formater.format(m);
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
    }

    override bool init()
    {
        client = new UdpSocket;
        return true;
    }

    override void log(Message m)
    {
        client.sendTo(formater.format(m), address);
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
