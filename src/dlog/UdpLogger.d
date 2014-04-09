module dlog.UdpLogger;

import dlog.LogBackend;
import dlog.Message;
import dlog.MessageFormater;
import dlog.Logger;

import std.socket;

class UdpLogger : LogBackend
{
    this(string host, ushort port, MessageFormater formater = new LineMessageFormater)
    {
        super(formater);
        .log.logging("UDP Logger endpoint : ", host, ":", port);
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
