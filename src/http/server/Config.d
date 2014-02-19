module http.server.Config;

import std.variant;

enum Parameter
{
	LOGGER,
	MAX_CONNECTION, 
	MAX_HEADER_SIZE, 
	BACKLOG, 
	KEEP_ALIVE_TIMEOUT, 
	MAX_REQUEST, 
	MAX_HEADER,
	CACHE,
	INSTALL_DIR,
	ROOT_DIR,
	SERVER_STRING,
	TOTAL_CPU,
	BAD_REQUEST_FILE,
	NOT_FOUND_FILE,
	NOT_ALLOWED_FILE
}

alias Variant[Parameter] Config;
