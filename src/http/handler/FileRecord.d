module http.handler.FileRecord;

import std.file;
import std.path;
import crunch.Caching;

class FileRecord : Cacheable!(string, string)
{
    private DirEntry m_de;
    private string m_indexFilename;

    this(string path, string indexFilename)
    {
        m_de = DirEntry(path);
        m_indexFilename = indexFilename;
    }

    override string key()
    {
        return m_de.name();
    }

    override string value()
    {
        if(m_de.isDir)
        {
            // load index file
            return readText(buildPath(m_de.name(), m_indexFilename));
        }
        return readText(m_de.name());
    }
}
