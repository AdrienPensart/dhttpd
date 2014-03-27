module http.handler.Directory;

import http.handler.Handler;
import http.handler.FileRecord;

import std.conv;
import std.regex;
import std.file;

import dlog.Logger;

import http.Options;

import http.protocol.Date;
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
        Options options;
        string directory;
        string indexFilename;
        string indexPath;
        string defaultMime;
    }

    this(string directory, string indexFilename, Options options)
    {
        this.options = options;
        this.directory = options[Parameter.ROOT_DIR].toString() ~ directory;
        this.indexFilename = indexFilename;
        this.defaultMime = defaultMime;
        FileRecord.enable_cache(options[Parameter.FILE_CACHE].get!(bool));
        this.mimes = options[Parameter.MIME_TYPES].get!(MimeMap);
        this.defaultMime = options[Parameter.DEFAULT_MIME].get!(string);
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
                return new NotAllowedResponse(options[Parameter.NOT_ALLOWED_FILE].toString());
            }

            auto finalPath = request.getPath();
            finalPath = replaceFirst(finalPath, regex(hit), directory);
            log.trace("Path asked : ", finalPath);

            Response response = new Response();
            response.status = Status.Ok;
            response.headers[FieldServer] = options[Parameter.SERVER_STRING].get!(string);
            response.headers[ContentType] = mimes.match(finalPath, defaultMime);
            response.headers[LastModified] = convertToRFC1123(timeLastModified(finalPath));

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
            return new NotFoundResponse(options[Parameter.NOT_FOUND_FILE].toString());
        }
    }
}
