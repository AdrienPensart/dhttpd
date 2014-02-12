module http.server.Options;

import std.variant;

enum Parameter { MAX_CONNECTION, BACKLOG, TIMEOUT, MAX_REQUEST, MAX_HEADER }
enum Default   { MAX_CONNECTION = 60, BACKLOG = 10, TIMEOUT = 5, MAX_REQUEST = 10, MAX_HEADER = 100 }

alias Default[Parameter] Options;
