module http.handler.Proxy;

import http.handler.Handler;
import dlog.Logger;

class Proxy : Handler
{
	this()
	{
		
	}
	
	override protected bool execute(Transaction transaction)
	{
		return true;
	}
}