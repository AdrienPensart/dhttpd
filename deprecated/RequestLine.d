module http.protocol.RequestLine;

import std.string;

import dlog.Logger;

import http.protocol.Version;
import http.protocol.Method;

class RequestLine
{
    Method method;
    Version protocolVersion;
    string uri;
    
    this(string rawLine)
    {
        this.rawLine = rawLine;
    }
    
    bool parse()
    {
        return parseHttpMethod() && parseHttpUri() && parseHttpVersion();
    }
    
    Method getMethod()
    {
        return method;
    }
    
    Version getProtocolVersion()
    {
        return protocolVersion;
    }
    
    string getUri()
    {
        return uri;
    }
    
    private:

        string rawLine;
        typeof(rawLine.length) methodIndex;
        typeof(rawLine.length) uriIndex;
        
        bool parseHttpMethod()
        {
            mixin(Tracer);
            methodIndex = indexOf(rawLine, ' ');
            if(methodIndex == -1)
            {
                return false;
            }
            auto method = rawLine[0..methodIndex];
            log.info("HTTP Method : ", method);
            foreach(validMethod ; [ EnumMembers!Method ])
            {
                if(method == validMethod)
                {
                    method = validMethod;
                    break;
                }
            }
            return method.length != 0;
        }
        
        bool parseHttpUri()
        {
            mixin(Tracer);
            uriIndex = indexOf(rawLine[methodIndex+1..$], ' ');
            if(uriIndex == -1)
            {
                return false;
            }
            uri = rawLine[methodIndex+1..methodIndex+1+uriIndex];
            log.info("HTTP URI received : '", uri, "'");
            return uri.length != 0;
        }
        
        bool parseHttpVersion()
        {
            mixin(Tracer);
            const auto startingProtocolVersion = methodIndex+1+uriIndex+1;           
            if(startingProtocolVersion > rawLine.length-2)
            {
                return false;
            }
            
            auto protocolVersionRead = rawLine[startingProtocolVersion..$-1];
            foreach(validProtocolVersion ; [ EnumMembers!Version ] )
            {
                if(protocolVersionRead == validProtocolVersion)
                {
                    protocolVersion = cast(Version)validProtocolVersion;
                    log.info("HTTP Version received : '", protocolVersion, "'");
                    break;
                }
            }
            return protocolVersion.length != 0;
        }
}

