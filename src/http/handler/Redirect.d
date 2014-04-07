module http.handler.Redirect;

import http.protocol.Method;
import http.protocol.Response;
import http.protocol.Status;
import http.protocol.Entity;
import http.protocol.Header;

import http.Transaction;
import http.handler.Handler;
import dlog.Logger;

class Redirect : Handler
{
	private
	{
		string m_location;
	}

	this(string a_location)
	{
		m_location = a_location;
	}

	void execute(Transaction transaction)
    {
        mixin(Tracer);
        log.trace("Redirecting");
        auto entity = new StringEntity;
        transaction.response = new Response(Status.MovedPerm, entity);
        transaction.response.headers[Location] = m_location;

        if(transaction.request.method == Method.GET)
        {
            entity.content="<a href=\""~m_location~"\">"~m_location~"</a>";
        }
    }
}
