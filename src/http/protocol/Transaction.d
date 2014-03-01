module http.protocol.Transaction;

import http.protocol.Request;
import http.protocol.Response;

import dlog.Logger;

class Transaction : AliveReference!Transaction
{
	Request request;
	Response response;
}
