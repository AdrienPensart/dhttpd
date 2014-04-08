module http.handler.Handler;

public import http.server.Transaction;

abstract class Handler
{
	protected bool execute(Transaction transaction);

	void addInputFilter(Handler inputFilter)
	{
		inputFilters ~= inputFilter;
	}

	void addOutputFilter(Handler outputFilter)
	{
		inputFilters ~= outputFilter;
	}

	void handle(Transaction transaction)
	{
		foreach(inputFilter ; inputFilters)
		{
			if(!inputFilter.execute(transaction))
			{
				return;
			}
		}
		if(execute(transaction))
		{
			foreach(outputFilter ; outputFilters)
			{
				if(!outputFilter.execute(transaction))
				{
					return;
				}
			}
		}
	}

	Handler[] inputFilters;
	Handler[] outputFilters;
}

/*
class ErrorHandler : Handler
{
	Response execute(Request request, string hit)
	{
		return true;
	}
}
*/
