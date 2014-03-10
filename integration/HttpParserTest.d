import std.traits;
import std.random;

string [] tokens = 
[
    EnumMembers!(Http.Header),
    EnumMembers!(Http.Version),
    EnumMembers!(Http.Method),
    "\r\n",
    "\n\r",
    "\r",
    "\n",
    ": ",
    ":",
    " ",
    "/",
    " "
];

class RandomRequestForger
{
    public:
        
        this(string[] tokens, uint complexity)
        {
            this.tokens = tokens;
            this.complexity = complexity;
        }

        string forge()
        {
            string request;
            for(uint nterm = 0; nterm <= complexity; nterm++)
            {
                auto index = uniform(0, tokens.length);
                request ~= tokens[index];
            }
            return request;
        }

    private:

        string [] tokens;
        uint complexity;
}

string [] requests = 
[
    "GET / HTTP/1.1\r\n"
    "Host: www.google.fr\r\n"
    "Connection: close\r\n"
    "User-Agent: Web-sniffer/1.0.37 (+http://web-sniffer.net/)\r\n"
    "Accept-Encoding: gzip\r\n"
    "Accept-Charset: ISO-8859-1,UTF-8;q=0.7,*;q=0.7\r\n"
    "Cache-Control: no-cache\r\n"
    "Accept-Language: de,en;q=0.7,en-us;q=0.3\r\n"
    "Referer: http://web-sniffer.net/\r\n"
    "\r\n",

    "\r\n",

    "",

    "\n",

    "GET / ", 

    "GET / \r\n",

    "GET / HTTP/1.1\r\n",

    "Host: www.google.fr\r\n",

    "GET / HTTP/1.1\r\n"
    "\r\n",
];

void heavyTest()
{
    auto p = new Http.Request;
    RandomRequestForger f = new RandomRequestForger(tokens,10);
    while(true)
    {
        p.parse(f.forge());
    }
}

void main()
{
    heavyTest();
}

