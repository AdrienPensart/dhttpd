module http.server.Options;

import std.variant;

enum { DEFAULT_SERVER_HEADER = "dhttpd" };
enum Parameter { MAX_CONNECTION, MAX_HEADER_SIZE, BACKLOG, TIMEOUT, MAX_REQUEST, MAX_HEADER }
enum Default   { MAX_CONNECTION = 60, MAX_HEADER_SIZE = 80*1024, BACKLOG = 10, TIMEOUT = 120, MAX_REQUEST = 10, MAX_HEADER = 100 }

alias Default[Parameter] Options;
