module http.protocol.Version;

enum ProtocolVersion : string
{
    HTTP_1_0 = "HTTP/1.0",
    HTTP_1_1 = "HTTP/1.1",
    HTTP_2_0 = "HTTP/2.0",
    DEFAULT  = HTTP_1_1
}

alias string Version;
immutable Version HTTP_1_0 = "HTTP/1.0";
immutable Version HTTP_1_1 = "HTTP/1.1";
immutable Version HTTP_2_0 = "HTTP/2.0";
immutable Version HTTP_DEFAULT = HTTP_1_1;
