module http.server.Directory;

import http.server.Handler;
import http.server.Connection;

class Directory : Handler
{
	this(string publicDir, string indexFilename)
    {
        this.publicDir = publicDir;
        this.indexFilename = indexFilename;
    }
        
	void execute(Connection connection)
	{

	}

    private:

        string publicDir;
        string indexFilename;
}