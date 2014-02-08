module HttpParser;
import std.stdio;

%%{
 
  machine http;
  expr = "h";
  #ok := expr+ @ { writeln("greetings!"); } ;
  ok := /GET/i ;
  main := '0x' xdigit+ | digit+ | alpha alnum*;
  
}%%

%% write data;
/*
void main()
{
    string test = "hhh";
    ulong dpe = test.length;
    
    char * p = cast(char*)test.ptr;
    char * pe = p + dpe;
    int cs;
    
    %% write init;
    %% write exec;
}
*/
