module http.protocol.Protocol;

/*
enum Protocol : string
{
    HTTP_1_0 = "HTTP/1.0",
    HTTP_1_1 = "HTTP/1.1",
    DEFAULT  = HTTP_1_1 //, HTTP_2_0 = "HTTP/2.0"
}
*/

alias string Protocol;
immutable Protocol HTTP_1_0 = "HTTP/1.0";
immutable Protocol HTTP_1_1 = "HTTP/1.1";
immutable Protocol HTTP_2_0 = "HTTP/2.0";
immutable Protocol HTTP_DEFAULT = HTTP_1_1;