module http.server.Client;

import std.socket;

import http.protocol.Request;

import dlog.Logger;
import dlog.Tracer;

class Client
{
    private:
        
        char[] lastChunk;
        Socket handle;
    
    public:
    
        this(Socket handle)
        {
            this.handle = handle;
        }
            
        Socket getHandle()
        {
            return handle;
        }
        
        char[] getLastChunk()
        {
            return lastChunk;
        }
        
        void close()
        {
            if(handle.isAlive)
            {
                handle.shutdown(SocketShutdown.BOTH);
            }
            handle.close();
        }
        
        bool readChunk()
        {
            mixin(Tracer);
            char buffer[1024];
            auto datalength = handle.receive(buffer);
            if (datalength == Socket.ERROR)
            {
                log.error("Connection error.");
                return false;
            }
            else if(datalength == 0)
            {
                log.info("Connection from ", handle.remoteAddress().toString(), " closed.");
                return false;
            }
            lastChunk = buffer[0 .. datalength];
            log.info("Received ", datalength, " bytes from ", handle.remoteAddress().toString(), "\n\"\n", lastChunk, "\n\"");
            return true;
        }
        
        bool writeChunk(string data)
        {
            mixin(Tracer);
            auto datalength = handle.send(data);
            if (datalength == Socket.ERROR)
            {
                log.error("Connection error.");
                return false;
            }
            else if(datalength == 0)
            {
                log.info("Connection from ", handle.remoteAddress().toString(), " closed.");
                return false;
            }
            log.info("Sent ", datalength, " bytes to ", handle.remoteAddress().toString(), "\n\"\n", data, "\n\"");
            return true;
        }
        
        bool isReady(SocketSet sset)
        {
            return cast(bool) sset.isSet(handle);
        }
}

