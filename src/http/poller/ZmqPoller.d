module http.poller.ZmqPoller;

import deimos.ev;
import zsockopt;

struct ZmqPoller
{
	ev_io m_io;
	ev_idle m_idle;
	ev_check m_check;
	ev_prepare m_prepare;
	void * m_socket;

	this(void * a_socket)
	{
		m_socket = a_socket;
		auto fd = zsocket_fd(m_socket);
	}
}
