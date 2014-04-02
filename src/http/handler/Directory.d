module http.handler.Directory;

import std.conv;
import std.regex;
import std.path;
import std.file;

import http.poller.FilePoller;
import dlog.Logger;
import crunch.Caching;

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
        static Cache!(string, FilePoller *) m_cache;
        MimeMap mimes;
        Options options;
        string directory;
        string indexFilename;
        string indexPath;
        string defaultMime;
    }

    this(Options options, string directory, string indexFilename="")
    {
        this.options = options;
        this.directory = options[Parameter.ROOT_DIR].toString() ~ directory;
        this.indexFilename = indexFilename;
        this.defaultMime = defaultMime;

        this.mimes = options[Parameter.MIME_TYPES].get!(MimeMap);
        this.defaultMime = options[Parameter.DEFAULT_MIME].get!(string);
    }
    
    FilePoller* loadFile(string finalPath, string indexFilename)
    {
        return new FilePoller(finalPath, Transaction.loop);
    }

    static void invalidateFile(string finalPath)
    {
        log.info("Invalidating file ", finalPath);
        m_cache.invalidate(finalPath);
    }

    void execute(Transaction transaction)
    {
        mixin(Tracer);
        try
        {
            auto request = transaction.request;
            Method method = request.getMethod();
            bool includeResource = method == Method.GET;

            if(method != Method.GET && method != Method.HEAD)
            {
                log.trace("Bad method ", method, " => Not Allowed");
                transaction.response = new NotAllowedResponse(options[Parameter.NOT_ALLOWED_FILE].toString());
                return;
            }

            auto finalPath = request.getPath();
            finalPath = replaceFirst(finalPath, regex(transaction.hit), directory);

            auto mde = DirEntry(finalPath);
            if(mde.isDir)
            {
                log.trace("Directory asked, serve index file");
                finalPath = buildPath(mde.name(), indexFilename);
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

            Response response = new Response;
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
                    transaction.response = new PreConditionFailedResponse;
                    return;
                }
            }

            import std.digest.md;
            response.headers[ContentType] = mimes.match(finalPath, defaultMime);
            response.headers[LastModified] = convertToRFC1123(timeLastModified(finalPath));
            response.headers[ContentMD5] = md5Of(response.content).toHexString.idup;
            response.headers[ETag] = etag;

            if(includeResource)
            {
                auto filePoller = m_cache.get(finalPath, { return loadFile(finalPath, indexFilename); } );
                transaction.poller = filePoller;
                response.content = filePoller.content;
            }
            transaction.response = response;
        }
        catch(FileException fe)
        {
            log.trace(fe);
            transaction.response = new NotFoundResponse(options[Parameter.NOT_FOUND_FILE].toString());
        }
    }
}
