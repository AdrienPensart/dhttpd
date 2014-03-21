module loop.InterruptionEvent;

import loop.EvLoop;
import dlog.Logger;

class InterruptionEvent
{
    this(EvLoop evloop)
    {
        parent = evloop;
        ev_signal_init (&interruptionWatcher, &interruption, SIGINT);
        ev_signal_start (parent.loop, &interruptionWatcher);
        interruptionWatcher.data = &children;
    }

    ~this()
    {
        //ev_signal_stop(parent.loop, &interruptionWatcher);
    }

    void addChild(EvLoop evLoop)
    {
        children ~= evLoop;
    }

    private
    {
        EvLoop parent;
        EvLoop [] children;
        ev_signal interruptionWatcher;
    }

    private extern(C) static void interruption (ev_loop_t * a_default_loop, ev_signal * a_interruption_watcher, int revents)
    {
        mixin(Tracer);
        log.error("Received SIGINT");
        auto children = cast(EvLoop [] *)a_interruption_watcher.data;
        foreach(child ; *children)
        {
            log.info("Sending async break to child ", child.id, ", loop : ", child.loop, ", watcher = ", child.stopWatcher);
            ev_async_send(child.loop, child.stopWatcher);
        }
        log.info("Breaking default loop : ", a_default_loop);
        ev_break(a_default_loop, EVBREAK_ALL);
    }
}
