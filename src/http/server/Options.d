module http.server.Options;

import std.variant;

enum Parameter
{
	DEFAULT_MIME,
	MIME_TYPES,

	TCP_REUSEPORT,
	TCP_REUSEADDR,
	TCP_CORK,
	TCP_NOWAIT,
	TCP_LINGER,
	TCP_NODELAY,
	TCP_SEND_BUFFER_SIZE,
	TCP_RECV_BUFFER_SIZE,

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