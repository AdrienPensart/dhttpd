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

    this(string directory, string indexFilename, Options options)
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
        auto mde = DirEntry(finalPath);        
        if(mde.isDir)
        {
            // load index file
            finalPath = buildPath(mde.name(), indexFilename);
        }
        else
        {
            finalPath = mde.name();
        }
        auto filePoller = new FilePoller(finalPath, Transaction.loop);
        return filePoller;
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
            if(method != Method.GET && method != Method.HEAD)
            {
                log.trace("Bad method ", method, " => Not Allowed");
                transaction.response = new NotAllowedResponse(options[Parameter.NOT_ALLOWED_FILE].toString());
                return;
            }

            auto finalPath = request.getPath();
            finalPath = replaceFirst(finalPath, regex(transaction.hit), directory);
            log.trace("Path asked : ", finalPath);

            Response response = new Response;
            response.status = Status.Ok;
            response.headers[FieldServer] = options[Parameter.SERVER_STRING].get!(string);
            response.headers[ContentType] = mimes.match(finalPath, defaultMime);
            response.headers[LastModified] = convertToRFC1123(timeLastModified(finalPath));

            import std.digest.ripemd;
            string etag = ripemd160Of(response.headers[LastModified]).toHexString.idup;
            response.headers[ETag] = etag;

            if(method == Method.GET)
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
