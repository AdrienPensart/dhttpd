module http.handler.Redirect;

import http.protocol.Method;
import http.protocol.Response;
import http.protocol.Status;
import http.protocol.StringEntity;
import http.protocol.Header;

import http.server.Transaction;
import http.handler.Handler;
import dlog.Logger;

class Redirect : Handler
{
	private
	{
		string m_location;
        Status m_status;
	}

	this(Status a_status, string a_location)
	{
        m_status = a_status;
		m_location = a_location;
	}

	override protected bool execute(Transaction transaction)
    {
        mixin(Tracer);
        log.trace("Redirecting");
        auto entity = new StringEntity;
        transaction.response = new Response(m_status, entity);
        transaction.response.headers[Location] = m_location;
        transaction.response.include = (transaction.request.method == Method.GET);

        if(transaction.response.include)
        {
            log.trace("Inserting hint link for redirection");
            entity.content="<a href=\""~m_location~"\">"~m_location~"</a>\n";
        }
        return true;
    }
}
