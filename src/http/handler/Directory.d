module http.handler.Directory;

import std.conv;
import std.regex;
import std.path;
import std.file;

import http.poller.FilePoller;
import dlog.Logger;

import http.server.Options;
import http.handler.Handler;

import http.protocol.Protocol;

class Directory : Handler
{
    private
    {
        MimeMap mimes;
        Options * m_options;
        string directory;
        string indexFilename;
        string indexPath;
        string defaultMime;
        string authentication;
    }

    this(Options * a_options, string a_directory, string a_indexFilename="")
    {
        mixin(Tracer);
        m_options = a_options;
        directory = a_directory;
        indexFilename = a_indexFilename;
        if(!isAbsolute(directory))
        {
            directory = buildPath(options[Parameter.ROOT_DIR].toString(), directory);
        }
        
        mimes = options[Parameter.MIME_TYPES].get!(MimeMap);
        defaultMime = options[Parameter.DEFAULT_MIME].get!(string);
    }

    private ref Options options()
    {
        return *m_options;
    }

    override protected bool execute(Transaction transaction)
    {
        mixin(Tracer);
        try
        {
            if(transaction.request.method != Method.GET && transaction.request.method != Method.HEAD)
            {
                log.trace("Bad method ", transaction.request.method, " => Not Allowed");
                transaction.response = options[Parameter.NOT_ALLOWED_RESPONSE].get!(Response);
                return false;
            }

            auto finalPath = transaction.request.getPath();
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
                    return false;
                }
            }
            else
            {
                log.trace("File asked, serve it");
                finalPath = mde.name();
            }
            log.trace("Path asked : ", finalPath);

            transaction.response = new Response(Status.Ok, new FileEntity(finalPath));
            transaction.response.include = (transaction.request.method == Method.GET);
            transaction.response.headers[ContentType] = mimes.match(finalPath, defaultMime);

            auto isIfMatch = IfMatch in transaction.request.headers;
            if(isIfMatch)
            {
                log.trace("if-match request");
            }

            auto isRangeRequest = Range in transaction.request.headers;
            if(isRangeRequest)
            {
                log.trace("range request");
                auto ifRangeData = IfRange in transaction.request.headers;
                if(ifRangeData)
                {
                    log.trace("if-range request");
                }
            }

            auto isIfNoneMatch = IfNoneMatch in transaction.request.headers;
            if(isIfNoneMatch)
            {
                log.trace("if-none-match request");
                if(*isIfNoneMatch == transaction.response.entity.etag)
                {
                    transaction.response.include = false;
                    transaction.response.status = Status.NotModified;
                }
            }

            auto modifiedSinceDate = IfModifiedSince in transaction.request.headers;
            if(modifiedSinceDate)
            {
                log.trace("Conditional GET : if-modified-since");
                if(*modifiedSinceDate == transaction.response.entity.lastModified)
                {
                    transaction.response.include = false;
                    transaction.response.status = Status.NotModified;
                }
            }

            auto unmodifiedSinceDate = IfUnmodifiedSince in transaction.request.headers;
            if(unmodifiedSinceDate)
            {
                log.trace("Conditional GET : if-unmodified-since");
                if(*unmodifiedSinceDate != transaction.response.entity.lastModified)
                {
                    transaction.response = options[Parameter.PRECOND_FAILED_RESPONSE].get!(Response);
                }
            }
        }
        catch(FileException fe)
        {
            log.trace(fe);
            transaction.response = options[Parameter.NOT_FOUND_RESPONSE].get!(Response);
        }
        return true;
    }
}
