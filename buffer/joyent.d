import std.bitmanip;
import std.ascii;
import std.c.stdlib;
import std.c.string;

const HTTP_MAX_HEADER_SIZE = 80*1024;

enum http_method
{
    HTTP_DELETE = 0, 
    HTTP_GET = 1, 
    HTTP_HEAD = 2, 
    HTTP_POST = 3, 
    HTTP_PUT = 4, 
    HTTP_CONNECT = 5, 
    HTTP_OPTIONS = 6, 
    HTTP_TRACE = 7, 
    HTTP_COPY = 8, 
    HTTP_LOCK = 9, 
    HTTP_MKCOL = 10, 
    HTTP_MOVE = 11, 
    HTTP_PROPFIND = 12, 
    HTTP_PROPPATCH = 13, 
    HTTP_SEARCH = 14, 
    HTTP_UNLOCK = 15, 
    HTTP_REPORT = 16, 
    HTTP_MKACTIVITY = 17, 
    HTTP_CHECKOUT = 18, 
    HTTP_MERGE = 19, 
    HTTP_MSEARCH = 20, 
    HTTP_NOTIFY = 21, 
    HTTP_SUBSCRIBE = 22, 
    HTTP_UNSUBSCRIBE = 23, 
    HTTP_PATCH = 24, 
    HTTP_PURGE = 25,
};

enum http_parser_type { HTTP_REQUEST, HTTP_RESPONSE, HTTP_BOTH };

enum http_flags
{
    F_CHUNKED = 1 << 0,
    F_CONNECTION_KEEP_ALIVE = 1 << 1,
    F_CONNECTION_CLOSE = 1 << 2,
    F_TRAILING = 1 << 3,
    F_UPGRADE = 1 << 4,
    F_SKIPBODY = 1 << 5
};

enum http_errno
{
    HPE_OK,
    HPE_CB_message_begin,
    HPE_CB_url,
    HPE_CB_header_field,
    HPE_CB_header_value,
    HPE_CB_headers_complete,
    HPE_CB_body,
    HPE_CB_message_complete,
    HPE_INVALID_EOF_STATE,
    HPE_HEADER_OVERFLOW,
    HPE_CLOSED_CONNECTION,
    HPE_INVALID_VERSION,
    HPE_INVALID_STATUS,
    HPE_INVALID_METHOD,
    HPE_INVALID_URL,
    HPE_INVALID_HOST,
    HPE_INVALID_PORT,
    HPE_INVALID_PATH,
    HPE_INVALID_QUERY_STRING,
    HPE_INVALID_FRAGMENT,
    HPE_LF_EXPECTED,
    HPE_INVALID_HEADER_TOKEN,
    HPE_INVALID_CONTENT_LENGTH,
    HPE_INVALID_CHUNK_SIZE,
    HPE_INVALID_CONSTANT,
    HPE_INVALID_INTERNAL_STATE,
    HPE_STRICT,
    HPE_PAUSED,
    HPE_UNKNOWN,
};

struct http_parser
{
    /*
    mixin(bitfields!(
        ubyte, "type", 2,
        ubyte, "flags", 6
    ));
    */
    
    http_flags flags;
    http_parser_type type;
    
    
    ubyte state;
    ubyte header_state;
    ubyte index;
    uint nread;
    ulong content_length;
    ushort http_major;
    ushort http_minor;
    ushort status_code;
    ubyte method;
/*
    mixin(bitfields!(
        ubyte, "http_errno_test", 7,
        ubyte, "upgrade", 1
    ));
*/
    http_errno errno;
    bool  upgrade;
        
    void * data;
    
    debug uint error_lineno;
    
    void setErrno(http_errno e)
    {
        errno = e;
        debug error_lineno = __LINE__;
    }
};

alias int function (http_parser*, const char *at, size_t length) http_data_cb;
alias int function (http_parser*) http_cb;

struct http_parser_settings {
    http_cb      on_message_begin;
    http_data_cb on_url;
    http_data_cb on_header_field;
    http_data_cb on_header_value;
    http_cb      on_headers_complete;
    http_data_cb on_body;
    http_cb      on_message_complete;
};

enum http_parser_url_fields
{
    UF_SCHEMA = 0,
    UF_HOST = 1,
    UF_PORT = 2,
    UF_PATH = 3,
    UF_QUERY = 4,
    UF_FRAGMENT = 5,
    UF_USERINFO = 6,
    UF_MAX = 7
};

struct http_parser_url {
    ushort field_set;
    ushort port;
    struct field_data_type
    {
        ushort off;
        ushort len;
    }
    
    field_data_type field_data[http_parser_url_fields.UF_MAX];
};

/*
void http_parser_init(http_parser *parser, http_parser_type type);
size_t http_parser_execute(http_parser *parser, const http_parser_settings *settings, const char *data, size_t len);
int http_should_keep_alive(http_parser *parser);
char *http_method_str(http_method m);
char *http_errno_name(http_errno err);
char *http_errno_description(http_errno err);
int http_parser_parse_url(const char *buf, size_t buflen,int is_connect, http_parser_url *u);
void http_parser_pause(http_parser *parse, int paused);
*/

const PROXY_CONNECTION = "proxy-connection";
const CONNECTION = "connection";
const CONTENT_LENGTH = "content-length";
const TRANSFER_ENCODING = "transfer-encoding";
const UPGRADE = "upgrade";
const CHUNKED = "chunked";
const KEEP_ALIVE = "keep-alive";
const CLOSE = "close";

static const char *method_strings[] =
[
    "DELETE",
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "CONNECT",
    "OPTIONS",
    "TRACE",
    "COPY",
    "LOCK",
    "MKCOL",
    "MOVE",
    "PROPFIND",
    "PROPPATCH",
    "SEARCH",
    "UNLOCK",
    "REPORT",
    "MKACTIVITY",
    "CHECKOUT",
    "MERGE",
    "M-SEARCH",
    "NOTIFY",
    "SUBSCRIBE",
    "UNSUBSCRIBE",
    "PATCH",
    "PURGE",
];

/* Tokens as defined by rfc 2616. Also lowercases them.
 *        token       = 1*<any CHAR except CTLs or separators>
 *     separators     = "(" | ")" | "<" | ">" | "@"
 *                    | "," | ";" | ":" | "\" | <">
 *                    | "/" | "[" | "]" | "?" | "="
 *                    | "{" | "}" | SP | HT
 */
static const byte tokens[256] = [
/*   0 nul    1 soh    2 stx    3 etx    4 eot    5 enq    6 ack    7 bel  */
        0,       0,       0,       0,       0,       0,       0,       0,
/*   8 bs     9 ht    10 nl    11 vt    12 np    13 cr    14 so    15 si   */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  16 dle   17 dc1   18 dc2   19 dc3   20 dc4   21 nak   22 syn   23 etb */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  24 can   25 em    26 sub   27 esc   28 fs    29 gs    30 rs    31 us  */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  32 sp    33  !    34  "    35  #    36  $    37  %    38  &    39  '  */
        0,      '!',      0,      '#',     '$',     '%',     '&',    '\'',
/*  40  (    41  )    42  *    43  +    44  ,    45  -    46  .    47  /  */
        0,       0,      '*',     '+',      0,      '-',     '.',      0,
/*  48  0    49  1    50  2    51  3    52  4    53  5    54  6    55  7  */
       '0',     '1',     '2',     '3',     '4',     '5',     '6',     '7',
/*  56  8    57  9    58  :    59  ;    60  <    61  =    62  >    63  ?  */
       '8',     '9',      0,       0,       0,       0,       0,       0,
/*  64  @    65  A    66  B    67  C    68  D    69  E    70  F    71  G  */
        0,      'a',     'b',     'c',     'd',     'e',     'f',     'g',
/*  72  H    73  I    74  J    75  K    76  L    77  M    78  N    79  O  */
       'h',     'i',     'j',     'k',     'l',     'm',     'n',     'o',
/*  80  P    81  Q    82  R    83  S    84  T    85  U    86  V    87  W  */
       'p',     'q',     'r',     's',     't',     'u',     'v',     'w',
/*  88  X    89  Y    90  Z    91  [    92  \    93  ]    94  ^    95  _  */
       'x',     'y',     'z',      0,       0,       0,      '^',     '_',
/*  96  `    97  a    98  b    99  c   100  d   101  e   102  f   103  g  */
       '`',     'a',     'b',     'c',     'd',     'e',     'f',     'g',
/* 104  h   105  i   106  j   107  k   108  l   109  m   110  n   111  o  */
       'h',     'i',     'j',     'k',     'l',     'm',     'n',     'o',
/* 112  p   113  q   114  r   115  s   116  t   117  u   118  v   119  w  */
       'p',     'q',     'r',     's',     't',     'u',     'v',     'w',
/* 120  x   121  y   122  z   123  {   124  |   125  }   126  ~   127 del */
       'x',     'y',     'z',      0,      '|',      0,      '~',       0 ];


static const byte unhex[256] =
  [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  , 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1
  ,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ];

version(HTTP_PARSER_STRICT)
{
    const T = 0;
}
else
{
    const T = 1;
}

static const ubyte normal_url_char[256] = [
/*   0 nul    1 soh    2 stx    3 etx    4 eot    5 enq    6 ack    7 bel  */
        0,       0,       0,       0,       0,       0,       0,       0,
/*   8 bs     9 ht    10 nl    11 vt    12 np    13 cr    14 so    15 si   */
        0,       T,       0,       0,       T,       0,       0,       0,
/*  16 dle   17 dc1   18 dc2   19 dc3   20 dc4   21 nak   22 syn   23 etb */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  24 can   25 em    26 sub   27 esc   28 fs    29 gs    30 rs    31 us  */
        0,       0,       0,       0,       0,       0,       0,       0,
/*  32 sp    33  !    34  "    35  #    36  $    37  %    38  &    39  '  */
        0,       1,       1,       0,       1,       1,       1,       1,
/*  40  (    41  )    42  *    43  +    44  ,    45  -    46  .    47  /  */
        1,       1,       1,       1,       1,       1,       1,       1,
/*  48  0    49  1    50  2    51  3    52  4    53  5    54  6    55  7  */
        1,       1,       1,       1,       1,       1,       1,       1,
/*  56  8    57  9    58  :    59  ;    60  <    61  =    62  >    63  ?  */
        1,       1,       1,       1,       1,       1,       1,       0,
/*  64  @    65  A    66  B    67  C    68  D    69  E    70  F    71  G  */
        1,       1,       1,       1,       1,       1,       1,       1,
/*  72  H    73  I    74  J    75  K    76  L    77  M    78  N    79  O  */
        1,       1,       1,       1,       1,       1,       1,       1,
/*  80  P    81  Q    82  R    83  S    84  T    85  U    86  V    87  W  */
        1,       1,       1,       1,       1,       1,       1,       1,
/*  88  X    89  Y    90  Z    91  [    92  \    93  ]    94  ^    95  _  */
        1,       1,       1,       1,       1,       1,       1,       1,
/*  96  `    97  a    98  b    99  c   100  d   101  e   102  f   103  g  */
        1,       1,       1,       1,       1,       1,       1,       1,
/* 104  h   105  i   106  j   107  k   108  l   109  m   110  n   111  o  */
        1,       1,       1,       1,       1,       1,       1,       1,
/* 112  p   113  q   114  r   115  s   116  t   117  u   118  v   119  w  */
        1,       1,       1,       1,       1,       1,       1,       1,
/* 120  x   121  y   122  z   123  {   124  |   125  }   126  ~   127 del */
        1,       1,       1,       1,       1,       1,       1,       0 ];

enum state {
   s_dead = 1, /* important that this is > 0 */
   s_start_req_or_res,
   s_res_or_resp_H,
   s_start_res,
   s_res_H,
   s_res_HT,
   s_res_HTT,
   s_res_HTTP,
   s_res_first_http_major,
   s_res_http_major,
   s_res_first_http_minor,
   s_res_http_minor,
   s_res_first_status_code,
   s_res_status_code,
   s_res_status,
   s_res_line_almost_done,
   s_start_req,
   s_req_method,
   s_req_spaces_before_url,
   s_req_schema,
   s_req_schema_slash,
   s_req_schema_slash_slash,
   s_req_server_start,
   s_req_server,
   s_req_server_with_at,
   s_req_path,
   s_req_query_string_start,
   s_req_query_string,
   s_req_fragment_start,
   s_req_fragment,
   s_req_http_start, 
   s_req_http_H,
   s_req_http_HT,
   s_req_http_HTT,
   s_req_http_HTTP,
   s_req_first_http_major,
   s_req_http_major,
   s_req_first_http_minor,
   s_req_http_minor,
   s_req_line_almost_done,
   s_header_field_start,
   s_header_field,
   s_header_value_start,
   s_header_value,
   s_header_value_lws,
   s_header_almost_done,
   s_chunk_size_start,
   s_chunk_size,
   s_chunk_parameters,
   s_chunk_size_almost_done,
   s_headers_almost_done,
   s_headers_done,

  /* Important: 's_headers_done' must be the last 'header' state. All
   * states beyond this must be 'body' states. It is used for overflow
   * checking. See the PARSING_HEADER() macro.
   */

   s_chunk_data,
   s_chunk_data_almost_done,
   s_chunk_data_done,
   s_body_identity,
   s_body_identity_eof,
   s_message_done
};

//#define PARSING_HEADER(state) (state <= s_headers_done)

enum header_states
{ 
  h_general = 0,
  h_C,
  h_CO,
  h_CON,
  h_matching_connection,
  h_matching_proxy_connection,
  h_matching_content_length,
  h_matching_transfer_encoding,
  h_matching_upgrade,
  h_connection,
  h_content_length,
  h_transfer_encoding,
  h_upgrade,
  h_matching_transfer_encoding_chunked,
  h_matching_connection_keep_alive,
  h_matching_connection_close,
  h_transfer_encoding_chunked,
  h_connection_keep_alive,
  h_connection_close
};

enum http_host_state
{
    s_http_host_dead = 1,
    s_http_userinfo_start,
    s_http_userinfo,
    s_http_host_start,
    s_http_host_v6_start,
    s_http_host,
    s_http_host_v6,
    s_http_host_v6_end,
    s_http_host_port_start,
    s_http_host_port
};

static struct http_strerror_tab_type
{
    const char *name;
    const char *description;
} 

http_strerror_tab_type http_strerror_tab [] = 
[
    { "HPE_" "OK", "success" },
    { "HPE_" "CB_message_begin", "the on_message_begin callback failed" },
    { "HPE_" "CB_url", "the on_url callback failed" },
    { "HPE_" "CB_header_field", "the on_header_field callback failed" },
    { "HPE_" "CB_header_value", "the on_header_value callback failed" },
    { "HPE_" "CB_headers_complete", "the on_headers_complete callback failed" },
    { "HPE_" "CB_body", "the on_body callback failed" },
    { "HPE_" "CB_message_complete", "the on_message_complete callback failed" },
    { "HPE_" "INVALID_EOF_STATE", "stream ended at an unexpected time" },
    { "HPE_" "HEADER_OVERFLOW", "too many header bytes seen; overflow detected" },
    { "HPE_" "CLOSED_CONNECTION", "data received after completed connection: close message" },
    { "HPE_" "INVALID_VERSION", "invalid HTTP version" },
    { "HPE_" "INVALID_STATUS", "invalid HTTP status code" },
    { "HPE_" "INVALID_METHOD", "invalid HTTP method" },
    { "HPE_" "INVALID_URL", "invalid URL" },
    { "HPE_" "INVALID_HOST", "invalid host" },
    { "HPE_" "INVALID_PORT", "invalid port" },
    { "HPE_" "INVALID_PATH", "invalid path" },
    { "HPE_" "INVALID_QUERY_STRING", "invalid query string" },
    { "HPE_" "INVALID_FRAGMENT", "invalid fragment" },
    { "HPE_" "LF_EXPECTED", "LF character expected" },
    { "HPE_" "INVALID_HEADER_TOKEN", "invalid character in header" },
    { "HPE_" "INVALID_CONTENT_LENGTH", "invalid character in content-length header" },
    { "HPE_" "INVALID_CHUNK_SIZE", "invalid character in chunk size header" },
    { "HPE_" "INVALID_CONSTANT", "invalid constant string" },
    { "HPE_" "INVALID_INTERNAL_STATE", "encountered unexpected internal state" },
    { "HPE_" "STRICT", "strict mode assertion failed" },
    { "HPE_" "PAUSED", "parser is paused" },
    { "HPE_" "UNKNOWN", "an unknown error occurred" },
];

int http_message_needs_eof (http_parser *parser)
{
    if (parser.type == http_parser_type.HTTP_REQUEST)
    {
        return 0;
    }
    /* See RFC 2616 section 4.4 */
    if (parser.status_code / 100 == 1 || /* 1xx e.g. Continue */
        parser.status_code == 204 ||     /* No Content */
        parser.status_code == 304 ||     /* Not Modified */
        parser.flags & http_flags.F_SKIPBODY)       /* response to a HEAD request */
    {     
        return 0;
    }

    if ((parser.flags & http_flags.F_CHUNKED) || parser.content_length != ulong.max)
    {
        return 0;
    }
    return 1;
}

bool isMark(dchar c)
{
    return c == '-' || c == '_' || c == '.' || c == '!' || c == '~' || c == '*' || c == '\'' || c == '(' || c == ')';
}

bool isUserInfoChar(dchar c)
{
    return isAlphaNum(c) || isMark(c) || c == '%' || c == ';' || c == ':' || c == '&' || c == '=' || c == '+' || c == '$' || c == ',';
}

bool isUrlChar(dchar c)
{
    version(HTTP_PARSER_STRICT)
    {
        return normal_url_char[cast(ubyte)c];
    }
    else
    {
        return normal_url_char[cast(ubyte)c] || (c & 0x80);
    }
}

bool isHostChar(dchar c)
{
    version(HTTP_PARSER_STRICT)
    {
        return isAlphaNum(c) || c == '.' || c == '-';
    }
    else
    {
        return isAlphaNum(c) || c == '.' || c == '-' || c == '_';
    }
}

char token(dchar c)
{
    version(HTTP_PARSER_STRICT)
    {
        return tokens[cast(ubyte)c];
    }
    else
    {
        return (c == ' ') ? ' ' : tokens[cast(ubyte)c];
    }
}

char * http_method_str (http_method m)
{
    return cast(char*)method_strings[m];
}


void http_parser_init (http_parser * parser, http_parser_type t)
{
    /* preserve application data */
    void * data = parser.data; 
    memset(parser, 0, parser.sizeof);
    parser.data = data;
    parser.type = t;
    parser.state = (t == http_parser_type.HTTP_REQUEST ? 
                   state.s_start_req : (t == http_parser_type.HTTP_RESPONSE ? state.s_start_res : state.s_start_req_or_res));
    parser.errno = http_errno.HPE_OK;
}

char * http_errno_name(http_errno err)
{
    assert(err < (http_strerror_tab.sizeof / http_strerror_tab[0].sizeof ));
    return cast(char *)http_strerror_tab[err].name;
}

char * http_errno_description(http_errno err)
{
    assert(err < (http_strerror_tab.sizeof / http_strerror_tab[0].sizeof ));
    return cast(char *)http_strerror_tab[err].description;
}

/* Our URL parser.
 *
 * This is designed to be shared by http_parser_execute() for URL validation,
 * hence it has a state transition + byte-for-byte interface. In addition, it
 * is meant to be embedded in http_parser_parse_url(), which does the dirty
 * work of turning state transitions URL components for its API.
 *
 * This function should only be invoked with non-space characters. It is
 * assumed that the caller cares about (and can detect) the transition between
 * URL and non-URL states by looking for these.
 */
static state parse_url_char(state s, const char ch)
{
    if (ch == ' ' || ch == '\r' || ch == '\n')
    {
        return state.s_dead;
    }

    version(HTTP_PARSER_STRICT)
    {
        if (ch == '\t' || ch == '\f')
        {
            return state.s_dead;
        }
    }

    switch (s)
    {
        case state.s_req_spaces_before_url:
            /* Proxied requests are followed by scheme of an absolute URI (alpha).
             * All methods except CONNECT are followed by '/' or '*'.
             */
            if (ch == '/' || ch == '*')
            {
                return state.s_req_path;
            }
            if (isAlpha(ch))
            {
                return state.s_req_schema;
            }
            break;
        case state.s_req_schema:
            if (isAlpha(ch))
            {
                return s;
            }
            if (ch == ':')
            {
                return state.s_req_schema_slash;
            }
            break;
        case state.s_req_schema_slash:
            if (ch == '/')
            {
                return state.s_req_schema_slash_slash;
            }
            break;
        case state.s_req_schema_slash_slash:
            if (ch == '/')
            {
                return state.s_req_server_start;
            }
            break;
        case state.s_req_server_with_at:
            if (ch == '@')
            {
                return state.s_dead;
            }
        /* FALLTHROUGH */
        case state.s_req_server_start:
        case state.s_req_server:
            if (ch == '/')
            {
                return state.s_req_path;
            }
            if (ch == '?')
            {
                return state.s_req_query_string_start;
            }
            if (ch == '@')
            {
                return state.s_req_server_with_at;
            }
            if (isUserInfoChar(ch) || ch == '[' || ch == ']')
            {
                return state.s_req_server;
            }
            break;
        case state.s_req_path:
            if (isUrlChar(ch))
            {
                return s;
            }
            switch (ch)
            {
                case '?':
                    return state.s_req_query_string_start;
                case '#':
                    return state.s_req_fragment_start;
                default:
                    break;
            }
            break;
        case state.s_req_query_string_start:
        case state.s_req_query_string:
            if (isUrlChar(ch))
            {
                return state.s_req_query_string;
            }
            switch (ch)
            {
                case '?':
                    /* allow extra '?' in query string */
                    return state.s_req_query_string;
                case '#':
                    return state.s_req_fragment_start;
                default:
                    break;
            }
            break;
        case state.s_req_fragment_start:
            if (isUrlChar(ch))
            {
                return state.s_req_fragment;
            }
            switch (ch)
            {
                case '?':
                    return state.s_req_fragment;
                case '#':
                    return s;
                default:
                    break;
            }
            break;
        case state.s_req_fragment:
            if (isUrlChar(ch))
            {
                return s;
            }
            switch (ch)
            {
                case '?':
                case '#':
                    return s;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    /* We should never fall out of the switch above unless there's an error */
    return state.s_dead;
}

static http_host_state http_parse_host_char(http_host_state s, const char ch)
{
    switch(s)
    {
        case http_host_state.s_http_userinfo:
        case http_host_state.s_http_userinfo_start:
            if (ch == '@')
            {
                return http_host_state.s_http_host_start;
            }
            if (isUserInfoChar(ch))
            {
                return http_host_state.s_http_userinfo;
            }
            break;
        case http_host_state.s_http_host_start:
            if (ch == '[')
            {
                return http_host_state.s_http_host_v6_start;
            }
            if (isHostChar(ch))
            {
                return http_host_state.s_http_host;
            }
            break;
        case http_host_state.s_http_host:
            if (isHostChar(ch))
            {
                return http_host_state.s_http_host;
            }
            /* FALLTHROUGH */
        case http_host_state.s_http_host_v6_end:
            if (ch == ':')
            {
                return http_host_state.s_http_host_port_start;
            }
            break;
        case http_host_state.s_http_host_v6:
            if (ch == ']')
            {
                return http_host_state.s_http_host_v6_end;
            }
            /* FALLTHROUGH */
        case http_host_state.s_http_host_v6_start:
            if (isHexDigit(ch) || ch == ':')
            {
                return http_host_state.s_http_host_v6;
            }
            break;
        case http_host_state.s_http_host_port:
        case http_host_state.s_http_host_port_start:
            if (isDigit(ch))
            {
                return http_host_state.s_http_host_port;
            }
            break;
        default:
            break;
    }
    return http_host_state.s_http_host_dead;
}

static int http_parse_host(char * buf, http_parser_url *u, int found_at)
{
    size_t buflen = u.field_data[http_parser_url_fields.UF_HOST].off + u.field_data[http_parser_url_fields.UF_HOST].len;
    u.field_data[http_parser_url_fields.UF_HOST].len = 0;

    http_host_state s = found_at ? http_host_state.s_http_userinfo_start : http_host_state.s_http_host_start;

    for (char * p = buf + u.field_data[http_parser_url_fields.UF_HOST].off; p < buf + buflen; p++)
    {
        http_host_state new_s = http_parse_host_char(s, *p);
        if (new_s == http_host_state.s_http_host_dead)
        {
            return 1;
        }
        switch(new_s)
        {
            case http_host_state.s_http_host:
                if (s != http_host_state.s_http_host)
                {
                    u.field_data[http_parser_url_fields.UF_HOST].off = cast(ushort)(p - buf);
                }
                u.field_data[http_parser_url_fields.UF_HOST].len++;
                break;
            case http_host_state.s_http_host_v6:
                if (s != http_host_state.s_http_host_v6)
                {
                    u.field_data[http_parser_url_fields.UF_HOST].off = cast(ushort)(p - buf);
                }
                u.field_data[http_parser_url_fields.UF_HOST].len++;
                break;
            case http_host_state.s_http_host_port:
                if (s != http_host_state.s_http_host_port)
                {
                    u.field_data[http_parser_url_fields.UF_PORT].off = cast(ushort)(p - buf);
                    u.field_data[http_parser_url_fields.UF_PORT].len = 0;
                    u.field_set |= (1 << http_parser_url_fields.UF_PORT);
                }
                u.field_data[http_parser_url_fields.UF_PORT].len++;
                break;
            case http_host_state.s_http_userinfo:
                if (s != http_host_state.s_http_userinfo)
                {
                    u.field_data[http_parser_url_fields.UF_USERINFO].off = cast(ushort)(p - buf);
                    u.field_data[http_parser_url_fields.UF_USERINFO].len = 0;
                    u.field_set |= (1 << http_parser_url_fields.UF_USERINFO);
                }
                u.field_data[http_parser_url_fields.UF_USERINFO].len++;
                break;
            default:
                break;
        }
        s = new_s;
    }

    /* Make sure we don't end somewhere unexpected */
    switch (s)
    {
        case http_host_state.s_http_host_start:
        case http_host_state.s_http_host_v6_start:
        case http_host_state.s_http_host_v6:
        case http_host_state.s_http_host_port_start:
        case http_host_state.s_http_userinfo:
        case http_host_state.s_http_userinfo_start:
            return 1;
        default:
            break;
    }
    return 0;
}

int http_parser_parse_url(char *buf, size_t buflen, int is_connect, http_parser_url *u)
{
    state s;
    http_parser_url_fields uf, old_uf;
    int found_at = 0;

    u.port = u.field_set = 0;
    s = is_connect ? state.s_req_server_start : state.s_req_spaces_before_url;
    uf = old_uf = http_parser_url_fields.UF_MAX;

    for (char * p = buf; p < buf + buflen; p++)
    {
        s = parse_url_char(s, *p);

        /* Figure out the next field that we're operating on */
        switch (s)
        {
            case state.s_dead:
                return 1;
            /* Skip delimeters */
            case state.s_req_schema_slash:
            case state.s_req_schema_slash_slash:
            case state.s_req_server_start:
            case state.s_req_query_string_start:
            case state.s_req_fragment_start:
                continue;
            case state.s_req_schema:
                uf = http_parser_url_fields.UF_SCHEMA;
                break;
            case state.s_req_server_with_at:
                found_at = 1;
            /* FALLTROUGH */  
            case state.s_req_server:
                uf = http_parser_url_fields.UF_HOST;
                break;
            case state.s_req_path:
                uf = http_parser_url_fields.UF_PATH;
                break;
            case state.s_req_query_string:
                uf = http_parser_url_fields.UF_QUERY;
                break;
            case state.s_req_fragment:
                uf = http_parser_url_fields.UF_FRAGMENT;
                break;
            default:
                assert(0, "Unexpected state");
                return 1;
        }

        /* Nothing's changed; soldier on */
        if (uf == old_uf)
        {
            u.field_data[uf].len++;
            continue;
        }

        u.field_data[uf].off = cast(ushort)(p - buf);
        u.field_data[uf].len = 1;
        u.field_set |= (1 << uf);
        old_uf = uf;
    }

    /* host must be present if there is a schema */
    /* parsing http:///toto will fail */
    if ((u.field_set & ((1 << http_parser_url_fields.UF_SCHEMA) | (1 << http_parser_url_fields.UF_HOST))) != 0)
    {
        if (http_parse_host(buf, u, found_at) != 0)
        {
            return 1;
        }
    }

    /* CONNECT requests can only contain "hostname:port" */
    if (is_connect && u.field_set != ((1 << http_parser_url_fields.UF_HOST)|(1 << http_parser_url_fields.UF_PORT)))
    {
        return 1;
    }

    if (u.field_set & (1 << http_parser_url_fields.UF_PORT))
    {
        /* Don't bother with endp; we've already validated the string */
        ulong v = strtoul(buf + u.field_data[http_parser_url_fields.UF_PORT].off, null, 10);

        /* Ports have a max value of 2^16 */
        if (v > 0xffff)
        {
            return 1;
        }
        u.port = cast(ushort) v;
    }
    return 0;
}

void http_parser_pause(http_parser *parser, int paused)
{
    /* Users should only be pausing/unpausing a parser that is not in an error
     * state. In non-debug builds, there's not much that we can do about this
     * other than ignore it.
     */
    if (parser.errno == http_errno.HPE_OK ||
        parser.errno == http_errno.HPE_PAUSED)
    {
        parser.setErrno((paused) ? http_errno.HPE_PAUSED : http_errno.HPE_OK);
    }
    else
    {
        assert(0, "Attempting to pause parser in error state");
    }
}

size_t http_parser_execute (http_parser * parser, const http_parser_settings *settings, char *data, size_t len)
{
    char c, ch;
    byte unhex_val;
    char * p = data;
    char * header_field_mark = null;
    char * header_value_mark = null;
    char * url_mark = null;
    char * body_mark = null;

    /* We're in an error state. Don't bother doing anything. */
    if (parser.errno != http_errno.HPE_OK)
    {
        return 0;
    }

    if (len == 0)
    {
        switch (parser.state)
        {
            case state.s_body_identity_eof:
                assert(parser.errno == http_errno.HPE_OK);
                if (settings.on_message_complete)
                {
                    if (0 != settings.on_message_complete(parser))
                    {
                        parser.errno = (http_errno.HPE_CB_message_complete);
                    }
                    if (parser.errno != http_errno.HPE_OK)
                    {
                        return (p - data);
                    }
                }
                return 0;
            case state.s_dead:
            case state.s_start_req_or_res:
            case state.s_start_res:
            case state.s_start_req:
                return 0;
            default:
                parser.setErrno(http_errno.HPE_INVALID_EOF_STATE);
                return 1;
        }
    }
    
    if (parser.state == state.s_header_field)
        header_field_mark = data;
    if (parser.state == state.s_header_value)
        header_value_mark = data;
    switch (parser.state)
    {
        case state.s_req_path:
        case state.s_req_schema:
        case state.s_req_schema_slash:
        case state.s_req_schema_slash_slash:
        case state.s_req_server_start:
        case state.s_req_server:
        case state.s_req_server_with_at:
        case state.s_req_query_string_start:
        case state.s_req_query_string:
        case state.s_req_fragment_start:
        case state.s_req_fragment:
            url_mark = data;
            break;
        default:
            break;
    }

    for (p=data; p != data + len; p++)
    {
        ch = *p;
        if (PARSING_HEADER(parser->state))
        {
            ++parser->nread;
            if (parser->nread > HTTP_MAX_HEADER_SIZE)
            {
                SET_ERRNO(HPE_HEADER_OVERFLOW);
                goto error;
            }
        }

        reexecute_byte:
        switch (parser->state)
        {
            case s_dead:
                if (ch == CR || ch == LF)
                    break;
                SET_ERRNO(HPE_CLOSED_CONNECTION);
                goto error;
            case s_start_req_or_res:
            {
                if (ch == CR || ch == LF)
                    break;
               parser->flags = 0;
               parser->content_length = ULLONG_MAX;
               if (ch == 'H')
               {
                   parser->state = s_res_or_resp_H;
                   CALLBACK_NOTIFY(message_begin);
               }
               else
               {
                   parser->type = HTTP_REQUEST;
                   parser->state = s_start_req;
                   goto reexecute_byte;
               }
               break;
           }
           case s_res_or_resp_H:
               if (ch == 'T')
               {
                   parser->type = HTTP_RESPONSE;
                   parser->state = s_res_HT;
               }
               else
               {
                   if (ch != 'E')
                   {
                       SET_ERRNO(HPE_INVALID_CONSTANT);
                       goto error;
                   }
                   parser->type = HTTP_REQUEST;
                   parser->method = HTTP_HEAD;
                   parser->index = 2;
                   parser->state = s_req_method;
               }
               break;
           case s_start_res:
           {
               parser->flags = 0;
               parser->content_length = ULLONG_MAX;
               switch (ch)
               {
                   case 'H':
                       parser->state = s_res_H;
                       break;
                   case CR:
                   case LF:
                       break;
                   default:
                       SET_ERRNO(HPE_INVALID_CONSTANT);
                       goto error;
               }
               CALLBACK_NOTIFY(message_begin);
               break;
          }
          case s_res_H:
              STRICT_CHECK(ch != 'T');
              parser->state = s_res_HT;
              break;
          case s_res_HT:
              STRICT_CHECK(ch != 'T');
              parser->state = s_res_HTT;
              break;
          case s_res_HTT:
              STRICT_CHECK(ch != 'P');
              parser->state = s_res_HTTP;
              break;
          case s_res_HTTP:
              STRICT_CHECK(ch != '/');
              parser->state = s_res_first_http_major;
              break;
          case s_res_first_http_major:
              if (ch < '0' || ch > '9')
              {
                  SET_ERRNO(HPE_INVALID_VERSION);
                  goto error;
              }
              parser->http_major = ch - '0';
              parser->state = s_res_http_major;
              break;
          case s_res_http_major:
              {
                  if (ch == '.')
                  {
                      parser->state = s_res_first_http_minor;
                      break;
                  }
                  if (!IS_NUM(ch))
                  {
                      SET_ERRNO(HPE_INVALID_VERSION);
                      goto error;
                  }

                  parser->http_major *= 10;
                  parser->http_major += ch - '0';
    
                  if (parser->http_major > 999) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        break;
      }

      /* first digit of minor HTTP version */
      case s_res_first_http_minor:
        if (!IS_NUM(ch)) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        parser->http_minor = ch - '0';
        parser->state = s_res_http_minor;
        break;

      /* minor HTTP version or end of request line */
      case s_res_http_minor:
      {
        if (ch == ' ') {
          parser->state = s_res_first_status_code;
          break;
        }

        if (!IS_NUM(ch)) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        parser->http_minor *= 10;
        parser->http_minor += ch - '0';

        if (parser->http_minor > 999) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        break;
      }

      case s_res_first_status_code:
      {
        if (!IS_NUM(ch)) {
          if (ch == ' ') {
            break;
          }

          SET_ERRNO(HPE_INVALID_STATUS);
          goto error;
        }
        parser->status_code = ch - '0';
        parser->state = s_res_status_code;
        break;
      }

      case s_res_status_code:
      {
        if (!IS_NUM(ch)) {
          switch (ch) {
            case ' ':
              parser->state = s_res_status;
              break;
            case CR:
              parser->state = s_res_line_almost_done;
              break;
            case LF:
              parser->state = s_header_field_start;
              break;
            default:
              SET_ERRNO(HPE_INVALID_STATUS);
              goto error;
          }
          break;
        }

        parser->status_code *= 10;
        parser->status_code += ch - '0';

        if (parser->status_code > 999) {
          SET_ERRNO(HPE_INVALID_STATUS);
          goto error;
        }

        break;
      }

      case s_res_status:
        /* the human readable status. e.g. "NOT FOUND"
         * we are not humans so just ignore this */
        if (ch == CR) {
          parser->state = s_res_line_almost_done;
          break;
        }

        if (ch == LF) {
          parser->state = s_header_field_start;
          break;
        }
        break;

      case s_res_line_almost_done:
        STRICT_CHECK(ch != LF);
        parser->state = s_header_field_start;
        break;

      case s_start_req:
      {
        if (ch == CR || ch == LF)
          break;
        parser->flags = 0;
        parser->content_length = ULLONG_MAX;

        if (!IS_ALPHA(ch)) {
          SET_ERRNO(HPE_INVALID_METHOD);
          goto error;
        }

        parser->method = (enum http_method) 0;
        parser->index = 1;
        switch (ch) {
          case 'C': parser->method = HTTP_CONNECT; /* or COPY, CHECKOUT */ break;
          case 'D': parser->method = HTTP_DELETE; break;
          case 'G': parser->method = HTTP_GET; break;
          case 'H': parser->method = HTTP_HEAD; break;
          case 'L': parser->method = HTTP_LOCK; break;
          case 'M': parser->method = HTTP_MKCOL; /* or MOVE, MKACTIVITY, MERGE, M-SEARCH */ break;
          case 'N': parser->method = HTTP_NOTIFY; break;
          case 'O': parser->method = HTTP_OPTIONS; break;
          case 'P': parser->method = HTTP_POST;
            /* or PROPFIND|PROPPATCH|PUT|PATCH|PURGE */
            break;
          case 'R': parser->method = HTTP_REPORT; break;
          case 'S': parser->method = HTTP_SUBSCRIBE; /* or SEARCH */ break;
          case 'T': parser->method = HTTP_TRACE; break;
          case 'U': parser->method = HTTP_UNLOCK; /* or UNSUBSCRIBE */ break;
          default:
            SET_ERRNO(HPE_INVALID_METHOD);
            goto error;
        }
        parser->state = s_req_method;

        CALLBACK_NOTIFY(message_begin);

        break;
      }

      case s_req_method:
      {
        const char *matcher;
        if (ch == '\0') {
          SET_ERRNO(HPE_INVALID_METHOD);
          goto error;
        }

        matcher = method_strings[parser->method];
        if (ch == ' ' && matcher[parser->index] == '\0') {
          parser->state = s_req_spaces_before_url;
        } else if (ch == matcher[parser->index]) {
          ; /* nada */
        } else if (parser->method == HTTP_CONNECT) {
          if (parser->index == 1 && ch == 'H') {
            parser->method = HTTP_CHECKOUT;
          } else if (parser->index == 2  && ch == 'P') {
            parser->method = HTTP_COPY;
          } else {
            goto error;
          }
        } else if (parser->method == HTTP_MKCOL) {
          if (parser->index == 1 && ch == 'O') {
            parser->method = HTTP_MOVE;
          } else if (parser->index == 1 && ch == 'E') {
            parser->method = HTTP_MERGE;
          } else if (parser->index == 1 && ch == '-') {
            parser->method = HTTP_MSEARCH;
          } else if (parser->index == 2 && ch == 'A') {
            parser->method = HTTP_MKACTIVITY;
          } else {
            goto error;
          }
        } else if (parser->method == HTTP_SUBSCRIBE) {
          if (parser->index == 1 && ch == 'E') {
            parser->method = HTTP_SEARCH;
          } else {
            goto error;
          }
        } else if (parser->index == 1 && parser->method == HTTP_POST) {
          if (ch == 'R') {
            parser->method = HTTP_PROPFIND; /* or HTTP_PROPPATCH */
          } else if (ch == 'U') {
            parser->method = HTTP_PUT; /* or HTTP_PURGE */
          } else if (ch == 'A') {
            parser->method = HTTP_PATCH;
          } else {
            goto error;
          }
        } else if (parser->index == 2) {
          if (parser->method == HTTP_PUT) {
            if (ch == 'R') parser->method = HTTP_PURGE;
          } else if (parser->method == HTTP_UNLOCK) {
            if (ch == 'S') parser->method = HTTP_UNSUBSCRIBE;
          }
        } else if (parser->index == 4 && parser->method == HTTP_PROPFIND && ch == 'P') {
          parser->method = HTTP_PROPPATCH;
        } else {
          SET_ERRNO(HPE_INVALID_METHOD);
          goto error;
        }

        ++parser->index;
        break;
      }

      case s_req_spaces_before_url:
      {
        if (ch == ' ') break;

        MARK(url);
        if (parser->method == HTTP_CONNECT) {
          parser->state = s_req_server_start;
        }

        parser->state = parse_url_char((enum state)parser->state, ch);
        if (parser->state == s_dead) {
          SET_ERRNO(HPE_INVALID_URL);
          goto error;
        }

        break;
      }

      case s_req_schema:
      case s_req_schema_slash:
      case s_req_schema_slash_slash:
      case s_req_server_start:
      {
        switch (ch) {
          /* No whitespace allowed here */
          case ' ':
          case CR:
          case LF:
            SET_ERRNO(HPE_INVALID_URL);
            goto error;
          default:
            parser->state = parse_url_char((enum state)parser->state, ch);
            if (parser->state == s_dead) {
              SET_ERRNO(HPE_INVALID_URL);
              goto error;
            }
        }

        break;
      }

      case s_req_server:
      case s_req_server_with_at:
      case s_req_path:
      case s_req_query_string_start:
      case s_req_query_string:
      case s_req_fragment_start:
      case s_req_fragment:
      {
        switch (ch) {
          case ' ':
            parser->state = s_req_http_start;
            CALLBACK_DATA(url);
            break;
          case CR:
          case LF:
            parser->http_major = 0;
            parser->http_minor = 9;
            parser->state = (ch == CR) ?
              s_req_line_almost_done :
              s_header_field_start;
            CALLBACK_DATA(url);
            break;
          default:
            parser->state = parse_url_char((enum state)parser->state, ch);
            if (parser->state == s_dead) {
              SET_ERRNO(HPE_INVALID_URL);
              goto error;
            }
        }
        break;
      }

      case s_req_http_start:
        switch (ch) {
          case 'H':
            parser->state = s_req_http_H;
            break;
          case ' ':
            break;
          default:
            SET_ERRNO(HPE_INVALID_CONSTANT);
            goto error;
        }
        break;

      case s_req_http_H:
        STRICT_CHECK(ch != 'T');
        parser->state = s_req_http_HT;
        break;

      case s_req_http_HT:
        STRICT_CHECK(ch != 'T');
        parser->state = s_req_http_HTT;
        break;

      case s_req_http_HTT:
        STRICT_CHECK(ch != 'P');
        parser->state = s_req_http_HTTP;
        break;

      case s_req_http_HTTP:
        STRICT_CHECK(ch != '/');
        parser->state = s_req_first_http_major;
        break;

      /* first digit of major HTTP version */
      case s_req_first_http_major:
        if (ch < '1' || ch > '9') {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        parser->http_major = ch - '0';
        parser->state = s_req_http_major;
        break;

      /* major HTTP version or dot */
      case s_req_http_major:
      {
        if (ch == '.') {
          parser->state = s_req_first_http_minor;
          break;
        }

        if (!IS_NUM(ch)) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        parser->http_major *= 10;
        parser->http_major += ch - '0';

        if (parser->http_major > 999) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        break;
      }

      /* first digit of minor HTTP version */
      case s_req_first_http_minor:
        if (!IS_NUM(ch)) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        parser->http_minor = ch - '0';
        parser->state = s_req_http_minor;
        break;

      /* minor HTTP version or end of request line */
      case s_req_http_minor:
      {
        if (ch == CR) {
          parser->state = s_req_line_almost_done;
          break;
        }

        if (ch == LF) {
          parser->state = s_header_field_start;
          break;
        }

        /* XXX allow spaces after digit? */

        if (!IS_NUM(ch)) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        parser->http_minor *= 10;
        parser->http_minor += ch - '0';

        if (parser->http_minor > 999) {
          SET_ERRNO(HPE_INVALID_VERSION);
          goto error;
        }

        break;
      }

      /* end of request line */
      case s_req_line_almost_done:
      {
        if (ch != LF) {
          SET_ERRNO(HPE_LF_EXPECTED);
          goto error;
        }

        parser->state = s_header_field_start;
        break;
      }

      case s_header_field_start:
      {
        if (ch == CR) {
          parser->state = s_headers_almost_done;
          break;
        }

        if (ch == LF) {
          /* they might be just sending \n instead of \r\n so this would be
           * the second \n to denote the end of headers*/
          parser->state = s_headers_almost_done;
          goto reexecute_byte;
        }

        c = TOKEN(ch);

        if (!c) {
          SET_ERRNO(HPE_INVALID_HEADER_TOKEN);
          goto error;
        }

        MARK(header_field);

        parser->index = 0;
        parser->state = s_header_field;

        switch (c) {
          case 'c':
            parser->header_state = h_C;
            break;

          case 'p':
            parser->header_state = h_matching_proxy_connection;
            break;

          case 't':
            parser->header_state = h_matching_transfer_encoding;
            break;

          case 'u':
            parser->header_state = h_matching_upgrade;
            break;

          default:
            parser->header_state = h_general;
            break;
        }
        break;
      }

      case s_header_field:
      {
        c = TOKEN(ch);

        if (c) {
          switch (parser->header_state) {
            case h_general:
              break;

            case h_C:
              parser->index++;
              parser->header_state = (c == 'o' ? h_CO : h_general);
              break;

            case h_CO:
              parser->index++;
              parser->header_state = (c == 'n' ? h_CON : h_general);
              break;

            case h_CON:
              parser->index++;
              switch (c) {
                case 'n':
                  parser->header_state = h_matching_connection;
                  break;
                case 't':
                  parser->header_state = h_matching_content_length;
                  break;
                default:
                  parser->header_state = h_general;
                  break;
              }
              break;

            /* connection */

            case h_matching_connection:
              parser->index++;
              if (parser->index > sizeof(CONNECTION)-1
                  || c != CONNECTION[parser->index]) {
                parser->header_state = h_general;
              } else if (parser->index == sizeof(CONNECTION)-2) {
                parser->header_state = h_connection;
              }
              break;

            /* proxy-connection */

            case h_matching_proxy_connection:
              parser->index++;
              if (parser->index > sizeof(PROXY_CONNECTION)-1
                  || c != PROXY_CONNECTION[parser->index]) {
                parser->header_state = h_general;
              } else if (parser->index == sizeof(PROXY_CONNECTION)-2) {
                parser->header_state = h_connection;
              }
              break;

            /* content-length */

            case h_matching_content_length:
              parser->index++;
              if (parser->index > sizeof(CONTENT_LENGTH)-1
                  || c != CONTENT_LENGTH[parser->index]) {
                parser->header_state = h_general;
              } else if (parser->index == sizeof(CONTENT_LENGTH)-2) {
                parser->header_state = h_content_length;
              }
              break;

            /* transfer-encoding */

            case h_matching_transfer_encoding:
              parser->index++;
              if (parser->index > sizeof(TRANSFER_ENCODING)-1
                  || c != TRANSFER_ENCODING[parser->index]) {
                parser->header_state = h_general;
              } else if (parser->index == sizeof(TRANSFER_ENCODING)-2) {
                parser->header_state = h_transfer_encoding;
              }
              break;

            /* upgrade */

            case h_matching_upgrade:
              parser->index++;
              if (parser->index > sizeof(UPGRADE)-1
                  || c != UPGRADE[parser->index]) {
                parser->header_state = h_general;
              } else if (parser->index == sizeof(UPGRADE)-2) {
                parser->header_state = h_upgrade;
              }
              break;

            case h_connection:
            case h_content_length:
            case h_transfer_encoding:
            case h_upgrade:
              if (ch != ' ') parser->header_state = h_general;
              break;

            default:
              assert(0 && "Unknown header_state");
              break;
          }
          break;
        }

        if (ch == ':') {
          parser->state = s_header_value_start;
          CALLBACK_DATA(header_field);
          break;
        }

        if (ch == CR) {
          parser->state = s_header_almost_done;
          CALLBACK_DATA(header_field);
          break;
        }

        if (ch == LF) {
          parser->state = s_header_field_start;
          CALLBACK_DATA(header_field);
          break;
        }

        SET_ERRNO(HPE_INVALID_HEADER_TOKEN);
        goto error;
      }

      case s_header_value_start:
      {
        if (ch == ' ' || ch == '\t') break;

        MARK(header_value);

        parser->state = s_header_value;
        parser->index = 0;

        if (ch == CR) {
          parser->header_state = h_general;
          parser->state = s_header_almost_done;
          CALLBACK_DATA(header_value);
          break;
        }

        if (ch == LF) {
          parser->state = s_header_field_start;
          CALLBACK_DATA(header_value);
          break;
        }

        c = LOWER(ch);

        switch (parser->header_state) {
          case h_upgrade:
            parser->flags |= F_UPGRADE;
            parser->header_state = h_general;
            break;

          case h_transfer_encoding:
            /* looking for 'Transfer-Encoding: chunked' */
            if ('c' == c) {
              parser->header_state = h_matching_transfer_encoding_chunked;
            } else {
              parser->header_state = h_general;
            }
            break;

          case h_content_length:
            if (!IS_NUM(ch)) {
              SET_ERRNO(HPE_INVALID_CONTENT_LENGTH);
              goto error;
            }

            parser->content_length = ch - '0';
            break;

          case h_connection:
            /* looking for 'Connection: keep-alive' */
            if (c == 'k') {
              parser->header_state = h_matching_connection_keep_alive;
            /* looking for 'Connection: close' */
            } else if (c == 'c') {
              parser->header_state = h_matching_connection_close;
            } else {
              parser->header_state = h_general;
            }
            break;

          default:
            parser->header_state = h_general;
            break;
        }
        break;
      }

      case s_header_value:
      {

        if (ch == CR) {
          parser->state = s_header_almost_done;
          CALLBACK_DATA(header_value);
          break;
        }

        if (ch == LF) {
          parser->state = s_header_almost_done;
          CALLBACK_DATA_NOADVANCE(header_value);
          goto reexecute_byte;
        }

        c = LOWER(ch);

        switch (parser->header_state) {
          case h_general:
            break;

          case h_connection:
          case h_transfer_encoding:
            assert(0 && "Shouldn't get here.");
            break;

          case h_content_length:
          {
            uint64_t t;

            if (ch == ' ') break;

            if (!IS_NUM(ch)) {
              SET_ERRNO(HPE_INVALID_CONTENT_LENGTH);
              goto error;
            }

            t = parser->content_length;
            t *= 10;
            t += ch - '0';

            /* Overflow? */
            if (t < parser->content_length || t == ULLONG_MAX) {
              SET_ERRNO(HPE_INVALID_CONTENT_LENGTH);
              goto error;
            }

            parser->content_length = t;
            break;
          }

          /* Transfer-Encoding: chunked */
          case h_matching_transfer_encoding_chunked:
            parser->index++;
            if (parser->index > sizeof(CHUNKED)-1
                || c != CHUNKED[parser->index]) {
              parser->header_state = h_general;
            } else if (parser->index == sizeof(CHUNKED)-2) {
              parser->header_state = h_transfer_encoding_chunked;
            }
            break;

          /* looking for 'Connection: keep-alive' */
          case h_matching_connection_keep_alive:
            parser->index++;
            if (parser->index > sizeof(KEEP_ALIVE)-1
                || c != KEEP_ALIVE[parser->index]) {
              parser->header_state = h_general;
            } else if (parser->index == sizeof(KEEP_ALIVE)-2) {
              parser->header_state = h_connection_keep_alive;
            }
            break;

          /* looking for 'Connection: close' */
          case h_matching_connection_close:
            parser->index++;
            if (parser->index > sizeof(CLOSE)-1 || c != CLOSE[parser->index]) {
              parser->header_state = h_general;
            } else if (parser->index == sizeof(CLOSE)-2) {
              parser->header_state = h_connection_close;
            }
            break;

          case h_transfer_encoding_chunked:
          case h_connection_keep_alive:
          case h_connection_close:
            if (ch != ' ') parser->header_state = h_general;
            break;

          default:
            parser->state = s_header_value;
            parser->header_state = h_general;
            break;
        }
        break;
      }

      case s_header_almost_done:
      {
        STRICT_CHECK(ch != LF);

        parser->state = s_header_value_lws;

        switch (parser->header_state) {
          case h_connection_keep_alive:
            parser->flags |= F_CONNECTION_KEEP_ALIVE;
            break;
          case h_connection_close:
            parser->flags |= F_CONNECTION_CLOSE;
            break;
          case h_transfer_encoding_chunked:
            parser->flags |= F_CHUNKED;
            break;
          default:
            break;
        }

        break;
      }

      case s_header_value_lws:
      {
        if (ch == ' ' || ch == '\t')
          parser->state = s_header_value_start;
        else
        {
          parser->state = s_header_field_start;
          goto reexecute_byte;
        }
        break;
      }

      case s_headers_almost_done:
      {
        STRICT_CHECK(ch != LF);

        if (parser->flags & F_TRAILING) {
          /* End of a chunked request */
          parser->state = NEW_MESSAGE();
          CALLBACK_NOTIFY(message_complete);
          break;
        }

        parser->state = s_headers_done;

        /* Set this here so that on_headers_complete() callbacks can see it */
        parser->upgrade =
          (parser->flags & F_UPGRADE || parser->method == HTTP_CONNECT);

        /* Here we call the headers_complete callback. This is somewhat
         * different than other callbacks because if the user returns 1, we
         * will interpret that as saying that this message has no body. This
         * is needed for the annoying case of recieving a response to a HEAD
         * request.
         *
         * We'd like to use CALLBACK_NOTIFY_NOADVANCE() here but we cannot, so
         * we have to simulate it by handling a change in errno below.
         */
        if (settings->on_headers_complete) {
          switch (settings->on_headers_complete(parser)) {
            case 0:
              break;

            case 1:
              parser->flags |= F_SKIPBODY;
              break;

            default:
              SET_ERRNO(HPE_CB_headers_complete);
              return p - data; /* Error */
          }
        }

        if (HTTP_PARSER_ERRNO(parser) != HPE_OK) {
          return p - data;
        }

        goto reexecute_byte;
      }

      case s_headers_done:
      {
        STRICT_CHECK(ch != LF);

        parser->nread = 0;

        /* Exit, the rest of the connect is in a different protocol. */
        if (parser->upgrade) {
          parser->state = NEW_MESSAGE();
          CALLBACK_NOTIFY(message_complete);
          return (p - data) + 1;
        }

        if (parser->flags & F_SKIPBODY) {
          parser->state = NEW_MESSAGE();
          CALLBACK_NOTIFY(message_complete);
        } else if (parser->flags & F_CHUNKED) {
          /* chunked encoding - ignore Content-Length header */
          parser->state = s_chunk_size_start;
        } else {
          if (parser->content_length == 0) {
            /* Content-Length header given but zero: Content-Length: 0\r\n */
            parser->state = NEW_MESSAGE();
            CALLBACK_NOTIFY(message_complete);
          } else if (parser->content_length != ULLONG_MAX) {
            /* Content-Length header given and non-zero */
            parser->state = s_body_identity;
          } else {
            if (parser->type == HTTP_REQUEST ||
                !http_message_needs_eof(parser)) {
              /* Assume content-length 0 - read the next */
              parser->state = NEW_MESSAGE();
              CALLBACK_NOTIFY(message_complete);
            } else {
              /* Read body until EOF */
              parser->state = s_body_identity_eof;
            }
          }
        }

        break;
      }

      case s_body_identity:
      {
        uint64_t to_read = MIN(parser->content_length,
                               (uint64_t) ((data + len) - p));

        assert(parser->content_length != 0
            && parser->content_length != ULLONG_MAX);

        /* The difference between advancing content_length and p is because
         * the latter will automaticaly advance on the next loop iteration.
         * Further, if content_length ends up at 0, we want to see the last
         * byte again for our message complete callback.
         */
        MARK(body);
        parser->content_length -= to_read;
        p += to_read - 1;

        if (parser->content_length == 0) {
          parser->state = s_message_done;

          /* Mimic CALLBACK_DATA_NOADVANCE() but with one extra byte.
           *
           * The alternative to doing this is to wait for the next byte to
           * trigger the data callback, just as in every other case. The
           * problem with this is that this makes it difficult for the test
           * harness to distinguish between complete-on-EOF and
           * complete-on-length. It's not clear that this distinction is
           * important for applications, but let's keep it for now.
           */
          CALLBACK_DATA_(body, p - body_mark + 1, p - data);
          goto reexecute_byte;
        }

        break;
      }

      /* read until EOF */
      case s_body_identity_eof:
        MARK(body);
        p = data + len - 1;

        break;

      case s_message_done:
        parser->state = NEW_MESSAGE();
        CALLBACK_NOTIFY(message_complete);
        break;

      case s_chunk_size_start:
      {
        assert(parser->nread == 1);
        assert(parser->flags & F_CHUNKED);

        unhex_val = unhex[(unsigned char)ch];
        if (unhex_val == -1) {
          SET_ERRNO(HPE_INVALID_CHUNK_SIZE);
          goto error;
        }

        parser->content_length = unhex_val;
        parser->state = s_chunk_size;
        break;
      }

      case s_chunk_size:
      {
        uint64_t t;

        assert(parser->flags & F_CHUNKED);

        if (ch == CR) {
          parser->state = s_chunk_size_almost_done;
          break;
        }

        unhex_val = unhex[(unsigned char)ch];

        if (unhex_val == -1) {
          if (ch == ';' || ch == ' ') {
            parser->state = s_chunk_parameters;
            break;
          }

          SET_ERRNO(HPE_INVALID_CHUNK_SIZE);
          goto error;
        }

        t = parser->content_length;
        t *= 16;
        t += unhex_val;

        /* Overflow? */
        if (t < parser->content_length || t == ULLONG_MAX) {
          SET_ERRNO(HPE_INVALID_CONTENT_LENGTH);
          goto error;
        }

        parser->content_length = t;
        break;
      }

      case s_chunk_parameters:
      {
        assert(parser->flags & F_CHUNKED);
        /* just ignore this shit. TODO check for overflow */
        if (ch == CR) {
          parser->state = s_chunk_size_almost_done;
          break;
        }
        break;
      }

      case s_chunk_size_almost_done:
      {
        assert(parser->flags & F_CHUNKED);
        STRICT_CHECK(ch != LF);

        parser->nread = 0;

        if (parser->content_length == 0) {
          parser->flags |= F_TRAILING;
          parser->state = s_header_field_start;
        } else {
          parser->state = s_chunk_data;
        }
        break;
      }

      case s_chunk_data:
      {
        uint64_t to_read = MIN(parser->content_length,
                               (uint64_t) ((data + len) - p));

        assert(parser->flags & F_CHUNKED);
        assert(parser->content_length != 0
            && parser->content_length != ULLONG_MAX);

        /* See the explanation in s_body_identity for why the content
         * length and data pointers are managed this way.
         */
        MARK(body);
        parser->content_length -= to_read;
        p += to_read - 1;

        if (parser->content_length == 0) {
          parser->state = s_chunk_data_almost_done;
        }

        break;
      }

      case s_chunk_data_almost_done:
        assert(parser->flags & F_CHUNKED);
        assert(parser->content_length == 0);
        STRICT_CHECK(ch != CR);
        parser->state = s_chunk_data_done;
        CALLBACK_DATA(body);
        break;

      case s_chunk_data_done:
        assert(parser->flags & F_CHUNKED);
        STRICT_CHECK(ch != LF);
        parser->nread = 0;
        parser->state = s_chunk_size_start;
        break;

      default:
        assert(0 && "unhandled state");
        SET_ERRNO(HPE_INVALID_INTERNAL_STATE);
        goto error;
    }
  }

  /* Run callbacks for any marks that we have leftover after we ran our of
   * bytes. There should be at most one of these set, so it's OK to invoke
   * them in series (unset marks will not result in callbacks).
   *
   * We use the NOADVANCE() variety of callbacks here because 'p' has already
   * overflowed 'data' and this allows us to correct for the off-by-one that
   * we'd otherwise have (since CALLBACK_DATA() is meant to be run with a 'p'
   * value that's in-bounds).
   */

  assert(((header_field_mark ? 1 : 0) +
          (header_value_mark ? 1 : 0) +
          (url_mark ? 1 : 0)  +
          (body_mark ? 1 : 0)) <= 1);

  CALLBACK_DATA_NOADVANCE(header_field);
  CALLBACK_DATA_NOADVANCE(header_value);
  CALLBACK_DATA_NOADVANCE(url);
  CALLBACK_DATA_NOADVANCE(body);

  return len;

error:
  if (HTTP_PARSER_ERRNO(parser) == HPE_OK) {
    SET_ERRNO(HPE_UNKNOWN);
  }
+/
    return (p - data);
}

void main()
{
}

