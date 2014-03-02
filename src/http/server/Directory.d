module http.server.Directory;

import std.conv;
import std.file;
import std.regex;
import std.path;
import dlog.Logger;

import http.server.Config;
import http.server.Handler;
import http.server.Cache;

import http.protocol.Mime;
import http.protocol.Header;
import http.protocol.Request;
import http.protocol.Response;
import http.protocol.Method;
import http.protocol.Status;

class Directory : Handler
{
    private
    {
        Config config;
        string directory;
        string indexFilename;
        string defaultMime;
    }

    this(Config config, string directory, string indexFilename, string defaultMime="application/octet-stream")
    {
        this.config = config;
        this.directory = config[Parameter.ROOT_DIR].toString() ~ directory;
        this.indexFilename = indexFilename;
        this.defaultMime = defaultMime;
    }
    
    Response execute(Request request, string hit)
    {
        mixin(Tracer);
        try
        {
            auto response = new Response();
            string finalPath = request.getPath();
            finalPath = replaceFirst(finalPath, regex(hit), directory);
            if(finalPath.isDir())
            {
                finalPath = buildPath(finalPath, indexFilename);
            }

            log.trace("Final path asked : ", finalPath);
            Method method = request.getMethod();
            if(method == Method.GET)
            {
                log.trace("GET method");
                response.headers[FieldServer] = config[Parameter.SERVER_STRING].get!(string);
                response.status = Status.Ok;

                auto mimes = config[Parameter.MIME_TYPES].get!(MimeMap);
                response.headers[ContentType] = mimes.match(finalPath, defaultMime);

                // cache lookup
                auto cache = config[Parameter.FILE_CACHE].get!(FileCache);
                UUID key = sha1UUID(finalPath);
                if(cache.exists(key))
                {
                    log.trace("Load file ", finalPath, " from cache with key ", key);
                    response.content = cache.get(key);
                }
                else
                {
                    log.trace("File ", finalPath, " is now in cache with key ", key);
                    response.content = readText(finalPath);
                    cache.add(key, response.content);
                    log.trace("New cache size : ", cache.length());
                }                
            }
            else if(method == Method.HEAD)
            {
                log.trace("HEAD method");
                response.headers[FieldServer] = config[Parameter.SERVER_STRING].toString();
                response.status = Status.Ok;
                response.headers[ContentType] = "text/html";
                response.headers[ContentLength] = to!string(getSize(finalPath));
            }
            else
            {
                log.trace("Bad method ", method, " => Not Allowed");
                auto notAllowedResponse = new NotAllowedResponse(config[Parameter.NOT_ALLOWED_FILE].toString());
                return notAllowedResponse;
            }
            return response;
        }
        catch(FileException fe)
        {
            log.trace(fe);
            auto notFoundResponse = new NotFoundResponse(config[Parameter.NOT_FOUND_FILE].toString());
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
}