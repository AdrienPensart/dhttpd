import Http;

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
