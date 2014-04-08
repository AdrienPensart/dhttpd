module http.handler.Authentication;

import http.handler.Handler;
import http.protocol.Protocol;
import http.server.Options;
import dlog.Logger;

import std.base64;
import std.regex;

enum { BASIC, DIGEST };

class Authentication : Handler
{
	private
	{
        static string m_basic_auth = "Basic ";
		static string m_basic_auth_rex = r"^Basic (?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4})$";
		string m_realm;
		string m_username;
		string m_password;
		string m_hash;
		string m_www_authenticate;
		Options * m_options;
	}

    private ref Options options()
    {
        return *m_options;
    }

	this(Options * a_options, string a_realm, string a_username, string a_password)
	{
		mixin(Tracer);
		m_options = a_options;
		m_realm = a_realm;
		m_username = a_username;
		m_password = a_password;
		m_www_authenticate = "Basic realm=\"" ~ m_realm ~ "\"";
		m_hash = Base64.encode(cast(ubyte[])(m_username ~ ":" ~ m_password));
	}

	override protected bool execute(Transaction transaction)
    {
        mixin(Tracer);

        auto auth = Authorization in transaction.request.headers;
        if(auth)
        {
        	log.trace("Basic authentication detected");
        	auto m = matchFirst(*auth, m_basic_auth_rex);
        	if(m)
        	{
                auto a_hash = m.hit[m_basic_auth.length..$];
        		log.trace("Basic authentication matched format, our hash = ", m_hash, ", request hash = ", a_hash);
                if(m_hash == a_hash)
                {
                    log.trace("VALID Username/Password");
        		    return true;
                }
                else
                {
                    log.trace("INVALID Username/Password");
                }
        	}
        	else
        	{
        		log.trace("Basic authentication didn't matched format");
        	}
        }
        else
        {
        	log.trace("Basic authentication not detected");
        }
        transaction.response = options[Parameter.UNAUTHORIZED_RESPONSE].get!(Response);
        transaction.response.headers[WWWAuthenticate] = m_www_authenticate;
        return false;
    }
}
