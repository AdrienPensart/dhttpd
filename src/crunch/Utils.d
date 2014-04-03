module crunch.Utils;

import std.parallelism : totalCPUs;
import std.path : dirName;
import std.file;
import std.socket;

auto installDir()
{
    return dirName(thisExePath());
}

auto availableCores()
{
    return totalCPUs;
}

void setCork(Socket a_socket, bool enable)
{
    enum TCP_CORK = 3;
    a_socket.setOption(SocketOptionLevel.TCP, cast(SocketOption)TCP_CORK, enable);
}

void setLinger(Socket a_socket, bool enable)
{
	if(enable)
	{
		Linger linger;
	    linger.on = 1;
	    linger.time = 1;
	    a_socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, linger);
	}
}

void setNoDelay(Socket a_socket, bool enable)
{
	if(enable)
	{
		a_socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
	}
}

void enableReuseAddr(Socket a_socket, bool enable)
{
	if(enable)
	{
		a_socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
	}
}

void enableReusePort(Socket a_socket, bool enable)
{
	if(enable)
	{
		enum REUSEPORT = 15;
		a_socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption)REUSEPORT, true);
	}
}

void enableDeferAccept(Socket a_socket, bool enable)
{
	if(enable)
	{
		enum TCP_DEFER_ACCEPT = 9;
        a_socket.setOption(SocketOptionLevel.TCP, cast(SocketOption)TCP_DEFER_ACCEPT, true);
	}
}
