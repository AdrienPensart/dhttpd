module crunch.FileSender;

import std.socket;
import std.stdio;

extern(C) size_t sendfile(int out_fd, int in_fd, size_t * offset, size_t count);

size_t sendFile(Socket a_socket, File a_file, size_t * offset, size_t count)
{
	return sendfile(cast(int)a_socket.handle, a_file.fileno(), offset, count);
}

struct FileSender
{
    ulong offset;
    ulong sent;
    ulong blockSize;

    bool send(Socket a_socket, File a_file, size_t maxBlock)
    {
    	auto length = a_file.size();
        blockSize = (length - sent) < maxBlock ? length : maxBlock;
        sent += a_socket.sendFile(a_file, &offset, blockSize);
        //log.trace("Sent ", sent, " bytes on ", poller.length, ", offset = ", offset, ", socket = ", socketFd);
        if(sent >= length)
        {
            offset = 0;
            sent = 0;
            blockSize = 0;
            return true;
        }
        return false;
    }
}
