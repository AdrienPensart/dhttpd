import HttpParsing;
import std.stdio;

void main()
{
    //auto httpParser = new HttpParser("GET /index.html HTTP/1.1\r\n\r\n");
    auto httpParser = new HttpParser();
    
    httpParser.execute("GET /path/file.html HTTP/1.0\nFrom");
    httpParser.execute(": someuser@jmarshall.com\nUser-Agent: HTTPTool/1.0\n\n");

    httpParser.finish();

    writeln("Request raw : ", httpParser.request);
}

