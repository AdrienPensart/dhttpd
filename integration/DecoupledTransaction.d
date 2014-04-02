/*
                if(EV_READ & revents)
                {
                    log.trace("Receiving request on ", connectionPoller.connection.handle());
                    if(connectionPoller.connection.recv())
                    {
                        ev_timer_again (loop, &connectionPoller.timer_io);
                        if(!connectionPoller.connection.empty())
                        {
                            log.trace("Activating response on ", connectionPoller.connection.handle());
                            connectionPoller.updateEvents(EV_WRITE | EV_READ);
                        }
                    }
                }

                if(EV_WRITE & revents)
                {
                    log.trace("Sending response on ", connectionPoller.connection.handle());
                    if(connectionPoller.connection.send())
                    {
                        ev_timer_again (loop, &connectionPoller.timer_io);
                        if(connectionPoller.connection.empty())
                        {
                            log.trace("Empty queue after sending response");
                            connectionPoller.updateEvents(EV_READ);
                        }
                    }
                }
                
                if(!connectionPoller.connection.valid())
                {
                    log.trace("Connection terminated.");
                    shutdown(connectionPoller);
                }
                */

private Transaction[] queue;
bool recv()
{
    mixin(Tracer);
    auto buffer = readChunk();
    if(!buffer.length)
    {
        return false;
    }
    
    if(currentRequest is null)
    {
        currentRequest = new Request();
    }

    log.trace("Feeding request on ", handle());
    currentRequest.feed(buffer);

    Transaction transaction = new Transaction(m_config, currentRequest);
    if(transaction.get() !is null)
    {
        log.trace("Pushing transaction into queue for ", handle());
        processedRequest++;
        queue ~= transaction;
        currentRequest = null;
    }
    return true;
}

bool send()
{
    mixin(Tracer);
    if(queue.empty)
    {
        log.trace("Empty queue on ", handle());
        return true;
    }

    auto transaction = queue.front();
    queue.popFront();
    return writeChunk(transaction.response.get()) && transaction.keepalive;
}

auto empty()
{
    return queue.empty();
}
