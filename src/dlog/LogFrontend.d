module dlog.LogFrontend;

import orange.serialization._;
import orange.serialization.archives._;

import dlog.Message;
import dlog.Logger;

import std.socket;
import core.thread;

abstract class LogFrontend : Thread
{
	this()
	{
		super(&run);
	}

	abstract void stop();
	abstract protected void handle();

	private	void run()
	{
		handle();
	}
}

class LogServer : LogFrontend
{
	this(ushort port)
	{
		set = new SocketSet;
		pair = socketPair();
		listener = new TcpSocket;
		listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
		listener.bind(new InternetAddress("0.0.0.0", port));
        listener.listen(16);
	}
	
	/*
	~this()
	{
		stop();
        logServer.join();
	}
	*/

	override void stop()
	{
		pair[1].send("interruption");
	}

	auto port()
	{
		return listener.localAddress().toPortString();
	}

	override protected void handle()
	{
		log.info("Starting log server on port ", port());
		while(1)
		{
			set.add(listener);
        	set.add(pair[0]);
			foreach(client ; clients)
			{
				set.add(client);
			}

			int result = Socket.select(set, null, null);
			if(result > 0)
			{
				if(set.isSet(listener))
				{
					Socket client = listener.accept();
					clients ~= client;
					set.add(client);
				}
				
				foreach(client; clients)
				{
					if(set.isSet(client))
					{
						char[64000] buffer;
						auto datalength = client.receive(buffer);
				        if (datalength == Socket.ERROR)
				        {
				            log.warning("Socket error : ", lastSocketError());
				        }
				        else if(datalength == 0)
				        {
				            log.trace("Disconnection on ", client.handle());
				        }

				        auto archive = new XmlArchive!(char);
				        archive.data = buffer;				     
				        auto serializer = new Serializer(archive);

				        Message message = serializer.deserialize!(Message)(archive.untypedData);
				        //auto message = new Message(buffer[0..datalength]);
				        //log.info(buffer[0..datalength]);
					}
				}

				if(set.isSet(pair[0]))
				{
					// interrupt thread
					return;
				}
			}
		}
	}

	private Socket[2] pair;
	private Socket listener;
	private Socket[] clients;
	private SocketSet set;
}
