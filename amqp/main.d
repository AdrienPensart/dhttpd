/*
    NotAJoy
    
    HTTP server.
    Auto adaptative strategy of request handling.
*/

import log;
import zmq;

import std.socket, std.stdio;

void main()
{
    try
    {
	zclock_sleep(1000);
	/*
        auto log = new Log();
        log.register(new ConsoleLogger());
        log.register(new FileLogger("access.log"), [Type.access]);
         
        auto rootDirectory = "/var/www/";
        log.info("Setting root path to ", rootDirectory);

        auto listener = new TcpSocket;
        //listener.blocking = false;
        listener.bind(new InternetAddress(8080));
        listener.listen(1024);
 
        while(true)
        {
            auto client = listener.accept();
        	client.send("Hello world");
	        client.shutdown(SocketShutdown.BOTH);
        	client.close();
        }
	*/
    }
    catch(Exception e)
    {
        writeln(e.msg);
    }
}

