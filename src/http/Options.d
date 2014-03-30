module http.Options;

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

    TCP_DEFER,
    TCP_REUSEPORT,
    TCP_REUSEADDR,

    MAX_CONNECTION, 
    MAX_HEADER_SIZE, 
    BACKLOG, 
    KEEP_ALIVE_TIMEOUT, 
    MAX_REQUEST, 
    MAX_HEADER,
    MAX_REQUEST_SIZE,
    HTTP_CACHE,
    FILE_CACHE,
    INSTALL_DIR,
    ROOT_DIR,
    SERVER_STRING,
    BAD_REQUEST_FILE,
    NOT_FOUND_FILE,
    NOT_ALLOWED_FILE
}

alias Variant[Parameter] Options;
