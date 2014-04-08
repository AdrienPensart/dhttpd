module http.server.Options;

import std.variant;

enum Parameter
{
    NB_THREADS,
    CONSOLE_LOGGING,

    GC_MODE,
    GC_TIMER,
    
    LOGGER_HOST,
    LOGGER_TCP_PORT,
    LOGGER_ZMQ_PORT,
    
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
