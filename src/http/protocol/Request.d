module http.protocol.Request;

import std.string;

import dlog.Logger;
import dlog.Tracer;

import http.protocol.RequestLine;
import http.protocol.RequestHeader;
import http.protocol.Header;

enum MAX_HEADER_SIZE = 80*1024;

class Request
{
    RequestLine rl;
    string[string] headers;
    string message;
    string rawRequest;
    
    this(string rawRequest)
    {
        this.rawRequest = rawRequest;
    }
    
    RequestLine getRequestLine()
    {
        return rl;
    }
    
    string getMessage()
    {
        return message;
    }
    
    string[string] getHeaders()
    {
        return headers;
    }
    
    bool parse()
    {
        mixin(Tracer);

        log.info("Raw data size : ", rawRequest.length);
        typeof(rawRequest.length) index = 0;

        auto lines = splitLines(rawRequest, KeepTerminator.yes);
        log.info("Raw number of lines : ", lines.length);

        if(lines.length >= 1)
        {
            rl = new RequestLine(lines[0]);
            // parsing the request line (first line of HTTP request)
            if(!rl.parse())
            {
                return false;
            }

            // parse the headers lines
            bool dataDetected = false;
            // Parsing the headers fields and detecting body data
            foreach(line ; lines[1..$])
            {
                log.info("Value of line : '", line, "'");
                // is it a header field, or the null line "\r\n" ?
                if(line.length >= 2)
                {
                    if(line[0] == '\r' && line[1] == '\n')
                    {
                        dataDetected = true;
                        break;
                    }
                }

                auto headerIndex = indexOf(line, ": ");
                if(headerIndex == -1)
                {
                    // it's not a header field, error detected
                    //debug (verbose) writeln("No header field");
                    return false;
                }
                auto header = line[0..headerIndex];
                string headerValue;
                foreach(validHeader ; [ EnumMembers!RequestHeader ])
                {
                    if(header == validHeader)
                    {
                        if(headerIndex+2 > line.length-2)
                        {
                            return false;
                        }
                        headerValue = line[headerIndex+2..$-2];
                    }
                }
                // invalid header field
                if(!headerValue.length)
                {
                    return false;
                }
                headers[header] = headerValue;
                log.info("headers[\"",header,"\"] = '", headerValue, "'");
            }
        }
        return true;
    }
}

