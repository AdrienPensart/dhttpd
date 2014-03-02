module http.server.Directory;

import std.conv;
import std.regex;
import std.file;

import dlog.Logger;

import http.server.Config;
import http.server.Handler;
import http.server.FileRecord;

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
        MimeMap mimes;
        Config config;
        string directory;
        string indexFilename;
        string indexPath;
        string defaultMime;
    }

    this(string directory, string indexFilename, Config config)
    {
        this.config = config;
        this.directory = config[Parameter.ROOT_DIR].toString() ~ directory;
        this.indexFilename = indexFilename;
        this.defaultMime = defaultMime;
        FileRecord.enable_cache(config[Parameter.FILE_CACHE].get!(bool));
        this.mimes = config[Parameter.MIME_TYPES].get!(MimeMap);
        this.defaultMime = config[Parameter.DEFAULT_MIME].get!(string);
    }
    
    Response execute(Request request, string hit)
    {
        mixin(Tracer);
        try
        {            
            Method method = request.getMethod();
            if(method != Method.GET && method != Method.HEAD)
            {
                log.trace("Bad method ", method, " => Not Allowed");
                return new NotAllowedResponse(config[Parameter.NOT_ALLOWED_FILE].toString());
            }

            string finalPath = request.getPath();
            finalPath = replaceFirst(finalPath, regex(hit), directory);
            log.trace("Path asked : ", finalPath);

            Response response = new Response();
            response.status = Status.Ok;
            response.headers[FieldServer] = config[Parameter.SERVER_STRING].get!(string);
            response.headers[ContentType] = mimes.match(finalPath, defaultMime);
            if(method == Method.GET)
            {
                scope auto file = new FileRecord(finalPath, indexFilename);
                response.content = file.get();
            }
            return response;
        }
        catch(FileException fe)
        {
            log.trace(fe);
            return new NotFoundResponse(config[Parameter.NOT_FOUND_FILE].toString());
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