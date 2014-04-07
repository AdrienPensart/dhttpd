module http.handler.Redirect;

import http.protocol.Response;
import http.protocol.Status;
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
        /*
        auto request = transaction.request;
        auto response = new Response;
        response.status = Status.MovedPerm;
        
        if(request.method == Method.HEAD)
        {
            response.content = "";
            return;
        }
        */
    }
}
