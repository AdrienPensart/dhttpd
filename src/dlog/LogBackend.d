module dlog.LogBackend;

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
    this(MessageFormater a_formater = new LineMessageFormater)
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
