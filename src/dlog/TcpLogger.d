module dlog.TcpLogger;

import dlog.LogBackend;
import dlog.Message;
import dlog.MessageFormater;
import dlog.Logger;

import std.socket;

class TcpLogger : LogBackend
{       
    this(string host, ushort port, MessageFormater formater = new BinaryMessageFormater)
    {
        super(formater);
        .log.logging("TCP Logger endpoint : ", host, ":", port);
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
            .log.logging("TcpLogger : Can't register to ", address, " : ", e.msg);
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
