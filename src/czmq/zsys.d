module zsys;

extern (C)
{
	enum UDP_FRAME_MAX = 255;

	//  Callback for interrupt signal handler
	alias void function (int signal_value) zsys_handler_fn;

	//  Set interrupt handler (NULL means external handler)
	void zsys_handler_set (zsys_handler_fn *handler_fn);

	//  Reset interrupt handler, call this at exit if needed
	void zsys_handler_reset ();
}
