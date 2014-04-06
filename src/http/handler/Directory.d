module http.handler.Directory;

import std.conv;
import std.regex;
import std.path;
import std.file;

import http.poller.FilePoller;
import dlog.Logger;

import http.Options;
import http.handler.Handler;
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

    this(Options a_options, string a_directory, string a_indexFilename="")
    {
        options = a_options;
        directory = a_directory;
        indexFilename = a_indexFilename;
        if(!isAbsolute(directory))
        {
            directory = buildPath(options[Parameter.ROOT_DIR].toString(), directory);
        }
        
        mimes = options[Parameter.MIME_TYPES].get!(MimeMap);
        defaultMime = options[Parameter.DEFAULT_MIME].get!(string);
    }
    
    static void invalidateFile(string finalPath)
    {
        log.info("Invalidating file ", finalPath);
        fileCache.invalidate(finalPath);
    }

    void execute(Transaction transaction)
    {
        mixin(Tracer);
        try
        {
            auto request = transaction.request;
            bool includeResource = request.method == Method.GET;

            if(request.method != Method.GET && request.method != Method.HEAD)
            {
                log.trace("Bad method ", request.method, " => Not Allowed");
                transaction.response = options[Parameter.NOT_ALLOWED_RESPONSE].get!(Response);
                return;
            }

            auto finalPath = request.getPath();
            finalPath = replaceFirst(finalPath, regex(transaction.hit), directory);

            auto mde = DirEntry(finalPath);
            if(mde.isDir)
            {
                if(indexFilename.length)
                {
                    log.trace("Directory asked, serve index file");
                    finalPath = buildPath(mde.name(), indexFilename);
                }
                else
                {
                    log.trace("No index file, we are not allowed to list directory");
                    transaction.response = options[Parameter.NOT_ALLOWED_RESPONSE].get!(Response);
                    return;
                }
            }
            else
            {
                log.trace("File asked, serve it");
                finalPath = mde.name();
            }

            auto lastModified = convertToRFC1123(timeLastModified(finalPath));
            log.trace("Path asked : ", finalPath);

            import std.digest.ripemd;
            auto etag = ripemd160Of(lastModified).toHexString.idup;

            auto isIfMatch = IfMatch in request.headers;
            if(isIfMatch)
            {
                log.trace("if-match request");
            }

            auto isRangeRequest = Range in request.headers;
            if(isRangeRequest)
            {
                log.trace("range request");
                auto ifRangeData = IfRange in request.headers;
                if(ifRangeData)
                {
                    log.trace("if-range request");
                }
            }

            auto response = new Response;
            response.status = Status.Ok;
            
            auto isIfNoneMatch = IfNoneMatch in request.headers;
            if(isIfNoneMatch)
            {
                log.trace("if-none-match request");
                if(*isIfNoneMatch == etag)
                {
                    includeResource = false;
                    response.status = Status.NotModified;
                }
            }

            auto modifiedSinceDate = IfModifiedSince in request.headers;
            if(modifiedSinceDate)
            {
                log.trace("Conditional GET : if-modified-since");
                if(*modifiedSinceDate == lastModified)
                {
                    includeResource = false;
                    response.status = Status.NotModified;
                }
            }

            auto unmodifiedSinceDate = IfUnmodifiedSince in request.headers;
            if(unmodifiedSinceDate)
            {
                log.trace("Conditional GET : if-unmodified-since");
                if(*unmodifiedSinceDate != lastModified)
                {
                    transaction.response = options[Parameter.PRECOND_FAILED_RESPONSE].get!(Response);
                    return;
                }
            }

            import std.digest.md;
            response.headers[ContentType] = mimes.match(finalPath, defaultMime);
            response.headers[LastModified] = convertToRFC1123(timeLastModified(finalPath));
            //response.headers[ContentMD5] = md5Of(response.content).toHexString.idup;
            response.headers[ETag] = etag;

            if(includeResource)
            {
                log.trace("Including resource in response");
                response.poller = fileCache.get(finalPath, { return new FilePoller(finalPath); } );
            }
            transaction.response = response;
            
        }
        catch(FileException fe)
        {
            log.trace(fe);
            transaction.response = options[Parameter.NOT_FOUND_RESPONSE].get!(Response);
        }
    }
}
