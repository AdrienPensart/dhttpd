module loop.InterruptionEvent;

import loop.Event;
import loop.EvLoop;
import dlog.Logger;

class InterruptionEvent : Event
{
    this(EvLoop evloop)
    {
        parent = evloop;
        interruptionWatcher.data = &children;
    }

    override void enable()
    {
        mixin(Tracer);
        ev_signal_init (&interruptionWatcher, &interruption, SIGINT);
        ev_signal_start (parent.loop, &interruptionWatcher);
    }

    override void disable()
    {
        mixin(Tracer);
        ev_signal_stop(parent.loop, &interruptionWatcher);
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
        log.info("Received interruption signal");
        auto children = cast(EvLoop [] *)a_interruption_watcher.data;
        foreach(child ; *children)
        {
            log.trace("Sending async break to child ", child.id, ", loop : ", child.loop, ", watcher = ", child.stopWatcher);
            ev_async_send(child.loop, child.stopWatcher);
        }
        log.trace("Breaking default loop : ", a_default_loop);
        ev_break(a_default_loop, EVBREAK_ALL);
    }
}
