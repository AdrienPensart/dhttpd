module http.server.Options;

import std.variant;
import dlog.Logger;

enum Parameter
{
    THREADS,
    CONSOLE_LOGGING,

    GC_MODE,
    GC_TIMER,
    
    FILE_LOG,
    ZMQ_LOG_HOST,
    ZMQ_LOG_PORT,
    TCP_LOG_HOST,
    TCP_LOG_PORT,
    UDP_LOG_HOST,
    UDP_LOG_PORT,
    
    DEFAULT_MIME,
    MIME_TYPES,

    TCP_CORK,
    TCP_NODELAY,
    TCP_LINGER,
    TCP_DEFER,
    TCP_REUSEPORT,
    TCP_REUSEADDR,

    MAX_CONNECTION, 
    MAX_HEADER_SIZE, 
    BACKLOG, 
    KEEP_ALIVE_TIMEOUT, 

    MAX_REQUEST, 
    MAX_HEADER,
    MAX_GET_REQUEST,
    MAX_PUT_REQUEST,
    MAX_POST_REQUEST,
    MAX_BLOCK,
    HTTP_CACHE,
    FILE_CACHE,
    
    INSTALL_DIR,
    ROOT_DIR,
    SERVER_STRING,

    BAD_REQUEST_PATH,
    NOT_FOUND_PATH,
    NOT_ALLOWED_PATH,
    UNAUTHORIZED_PATH,

    BAD_REQUEST_RESPONSE,
    ENTITY_TOO_LARGE_RESPONSE,
    PRECOND_FAILED_RESPONSE,
    NOT_FOUND_RESPONSE,
    NOT_ALLOWED_RESPONSE,
    UNAUTHORIZED_RESPONSE
}

alias Variant[Parameter] Options;

// now we can write options.get!Response(BAD_REQUEST_RESPONSE)
T get(T)(ref Options options, Parameter parameter)
{
    if( (parameter in options) is null)
    {
        log.warning("Parameter ", parameter, " not found in options");
        return T.init;
    }
    return *options[parameter].peek!(T);
}
