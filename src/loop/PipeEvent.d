module loop.PipeEvent;

import loop.Event;
import loop.EvLoop;
import dlog.Logger;

class PipeEvent : Event
{
    this(EvLoop evloop)
    {
       	parent = evloop;
    }

    override void enable()
    {
        mixin(Tracer);
        import core.sys.posix.signal;
        ev_signal_init (&pipeWatcher, &interruption, SIGPIPE);
        ev_signal_start (parent.loop, &pipeWatcher);
    }

    override void disable()
    {
        mixin(Tracer);
        ev_signal_stop(parent.loop, &pipeWatcher);
    }

    private extern(C) static void interruption (ev_loop_t * a_default_loop, ev_signal * a_interruption_watcher, int revents)
    {
        mixin(Tracer);
        log.info("Received sigpipe signal");
    }

    private
    {
        EvLoop parent;
        ev_signal pipeWatcher;
    }
}
