module http.server.LocationListener;

// Route level
class LocationListener
{    
    this(string publicDir, string indexFilename)
    {
        this.publicDir = publicDir;
        this.indexFilename = indexFilename;
    }
        
    private:

        string publicDir;
        string indexFilename;
}
