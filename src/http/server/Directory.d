module http.server.Directory;

import std.conv;
import std.file;
import std.regex;
import std.path;
import dlog.Logger;

import http.server.Config;
import http.server.Handler;

import http.protocol.Header;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Method;
import http.protocol.Status;

class Directory : Handler
{
    this(string directory, string indexFilename, bool authListing=false)
    {
        this.directory = directory;
        this.indexFilename = indexFilename;
    }
    
    
    
    Response execute(Request request, string hit)
    {
        try
        {
            auto response = new Response();
            string finalPath = request.getPath();
            finalPath = replaceFirst(finalPath, regex(hit), directory);
            if(finalPath.isDir())
            {
                finalPath = buildPath(finalPath, indexFilename);
            }

            log.info("Final path asked : ", finalPath);
            Method method = request.getMethod();
            if(method == Method.GET)
            {
                log.info("GET method");
                response.headers[Header.Server] = Config.getServerString();
                response.protocol = request.getProtocol();
                response.status = Status.Ok;
                response.headers[Header.ContentType] = "text/html";
                response.content = readText(finalPath);
                
            }
            else if(method == Method.HEAD)
            {
                log.info("HEAD method");
                response.headers[Header.Server] = Config.getServerString();
                response.protocol = request.getProtocol();
                response.status = Status.Ok;
                response.headers[Header.ContentType] = "text/html";
                response.headers[Header.ContentLength] = to!string(getSize(finalPath));
            }
            else
            {
                log.info("Bad method ", method, " => Not Allowed");
                auto notAllowedResponse = new NotAllowedResponse();
                return notAllowedResponse;
            }
            return response;
        }
        catch(FileException fe)
        {
            log.info(fe);
            auto notFoundResponse = new NotFoundResponse();
            return notFoundResponse;
        }
    }

    private bool headRequest()
    {
        return true;
    }

    private bool getRequest()
    {
        return true;
    }

    private:

        string directory;
        string indexFilename;
}