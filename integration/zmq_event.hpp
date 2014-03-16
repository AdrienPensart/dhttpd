#include <string>

#include <ev++.h>
#include <zmq.hpp>

class zmq_event {
    public:
        zmq_event(zmq::context_t& context, int type, const std::string& connect);
        virtual ~zmq_event();

    protected:
        // This gets fired before the event loop, to prepare
        void before(ev::prepare& prep, int revents);

        // This is fired after the event loop, but before any other type of events
        void after(ev::check& check, int revents);

        // We need to have a no-op function available for those events that we
        // want to add to the list, but should never fire an actual event
        template <typename T>
            inline void noop(T& w, int revents) {};

        // Function we are going to call to write to the ZeroMQ socket
        virtual void write() = 0;

        // Function we are going to call to read from the ZeroMQ socket
        virtual void read() = 0;

        // Some helper function, one to start notifications
        void start_notify();

        // And one to stop notifications.
        void stop_notify();

        // Our event types
        ev::io      watcher_io;
        ev::prepare watcher_prepare;
        ev::check   watcher_check;
        ev::idle    watcher_idle;

        // Our ZeroMQ socket
        zmq::socket_t socket;
        int           socket_fd = -1;
};