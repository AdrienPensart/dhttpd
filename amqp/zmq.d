module Zmq;

import std.c.stdio;

extern(C)
{
    void zclock_sleep (int msecs);
    long zclock_time ();
    void zclock_log (const char *format, ...);
    int zclock_test (bool verbose);

    alias void zctx_t;

    zctx_t * zctx_new ();

    void zctx_destroy (zctx_t **self_p);
    zctx_t * zctx_shadow (zctx_t *self);
    void zctx_set_iothreads (zctx_t *self, int iothreads);
    void zctx_set_linger (zctx_t *self, int linger);
    void zctx_set_hwm (zctx_t *self, int hwm);
    int zctx_hwm (zctx_t *self);
    void * zctx_underlying (zctx_t *self);
    int zctx_test (bool verbose);
    int zctx_interrupted;
    void * zctx__socket_new (zctx_t *self, int type);
    void zctx__socket_destroy (zctx_t *self, void *socket);

    int zfile_delete (const char *filename);
    int zfile_mkdir (const char *dirname);
    int zfile_exists (const char *filename);
    size_t zfile_size (const char *filename);
    int zfile_test (bool verbose);

    alias void zframe_t;

    enum { ZFRAME_MORE = 1, ZFRAME_REUSE = 2, ZFRAME_DONTWAIT = 4};

    alias void function (void *data, void *arg) zframe_free_fn;

    zframe_t * zframe_new (const void *data, size_t size);
    zframe_t * zframe_new_zero_copy (void *data, size_t size, zframe_free_fn *free_fn, void *arg);
    void zframe_destroy (zframe_t **self_p);
    zframe_t * zframe_recv (void *socket);
    zframe_t * zframe_recv_nowait (void *socket);
    int zframe_send (zframe_t **self_p, void *socket, int flags);
    size_t zframe_size (zframe_t *self);
    byte * zframe_data (zframe_t *self);
    zframe_t * zframe_dup (zframe_t *self);
    char * zframe_strhex (zframe_t *self);
    char * zframe_strdup (zframe_t *self);
    bool zframe_streq (zframe_t *self, const char *string);
    int zframe_zero_copy (zframe_t *self);
    int zframe_more (const zframe_t *self);
    bool zframe_eq (zframe_t *self, zframe_t *other);
    void zframe_print (zframe_t *self, const char *prefix);
    void zframe_reset (zframe_t *self, const void *data, size_t size);
    int zframe_test (bool verbose);

    alias void zhash_t;

    alias int function  (const char *key, void *item, void *argument) zhash_foreach_fn;
    alias void function (void *data) zhash_free_fn;

    zhash_t * zhash_new ();
    void zhash_destroy (zhash_t **self_p);
    void zhash_update (zhash_t *self, const char *key, void *item);
    void zhash_delete (zhash_t *self, const char *key);
    void * zhash_lookup (zhash_t *self, const char *key);
    int zhash_rename (zhash_t *self, const char *old_key, const char *new_key);
    void * zhash_freefn (zhash_t *self, const char *key, zhash_free_fn *free_fn);

    size_t zhash_size (zhash_t *self);
    int zhash_foreach (zhash_t *self, zhash_foreach_fn *callback, void *argument);
    void zhash_test (int verbose);

    alias void zlist_t;
    zlist_t * zlist_new ();
    void zlist_destroy (zlist_t **self_p);
    void * zlist_first (zlist_t *self);
    void * zlist_last (zlist_t *self);
    void * zlist_head (zlist_t *self);
    void * zlist_tail (zlist_t *self);
    void * zlist_next (zlist_t *self);
    int zlist_append (zlist_t *self, void *item);
    int zlist_push (zlist_t *self, void *item);
    void * zlist_pop (zlist_t *self);
    void zlist_remove (zlist_t *self, void *item);
    zlist_t * zlist_copy (zlist_t *self);
    size_t zlist_size (zlist_t *self);
    void zlist_test (int verbose);

    alias void zloop_t;
    alias void zmq_pollitem_t;
    
    alias int function (zloop_t *loop, zmq_pollitem_t *item, void *arg) zloop_fn;

    zloop_t * zloop_new ();
    void zloop_destroy (zloop_t **self_p);
    int zloop_poller (zloop_t *self, zmq_pollitem_t *item, zloop_fn handler, void *arg);
    void zloop_poller_end (zloop_t *self, zmq_pollitem_t *item);
    int zloop_timer (zloop_t *self, size_t delay, size_t times, zloop_fn handler, void *arg);
    int zloop_timer_end (zloop_t *self, void *arg);
    void zloop_set_verbose (zloop_t *self, bool verbose);
    int zloop_start (zloop_t *self);
    int zloop_test (bool verbose);
    
    alias void zmsg_t;
    zmsg_t * zmsg_new ();
    void zmsg_destroy (zmsg_t **self_p);
    zmsg_t * zmsg_recv (void *socket);
    void msg_send (zmsg_t **self_p, void *socket);
    size_t zmsg_size (zmsg_t *self);
    size_t zmsg_content_size (zmsg_t *self);
    int zmsg_push (zmsg_t *self, zframe_t *frame);
    zframe_t * zmsg_pop (zmsg_t *self);
    int zmsg_add (zmsg_t *self, zframe_t *frame);
    int zmsg_pushmem (zmsg_t *self, const void *src, size_t size);
    int zmsg_addmem (zmsg_t *self, const void *src, size_t size);
    int zmsg_pushstr (zmsg_t *self, const char *format, ...);
    int zmsg_addstr (zmsg_t *self, const char *format, ...);
    char * zmsg_popstr (zmsg_t *self);
    void zmsg_wrap (zmsg_t *self, zframe_t *frame);
    zframe_t * zmsg_unwrap (zmsg_t *self);
    void zmsg_remove (zmsg_t *self, zframe_t *frame);
    zframe_t * zmsg_first (zmsg_t *self);
    zframe_t * zmsg_next (zmsg_t *self);
    zframe_t * zmsg_last (zmsg_t *self);
    int zmsg_save (zmsg_t *self, FILE *file);
    zmsg_t * zmsg_load (zmsg_t *self, FILE *file);
    size_t zmsg_encode (zmsg_t *self, byte **buffer);
    zmsg_t * zmsg_decode (byte *buffer, size_t buffer_size);
    zmsg_t * zmsg_dup (zmsg_t *self);
    void zmsg_dump (zmsg_t *self);
    int zmsg_test (bool verbose);
    /*
    enum { ZSOCKET_DYNFROM = 0xc000,ZSOCKET_DYNTO = 0xffff };

    void * zsocket_new (zctx_t *self, int type);
    void zsocket_destroy (zctx_t *self, void *socket);
    int zsocket_bind (void *socket, const char *format, ...);
    int zsocket_connect (void *socket, const char *format, ...);

    #if (ZMQ_VERSION >= ZMQ_MAKE_VERSION(3,3,0))
        int zsocket_disconnect (void *socket, const char *format, ...);
    #endif

    bool zsocket_poll (void *socket, int msecs);
    char * zsocket_type_str (void *socket);
    int zsocket_test (Bool verbose);
    
    #if (ZMQ_VERSION_MAJOR == 2)
    //  Get socket options
    int zsocket_hwm (void *socket);
    int zsocket_swap (void *socket);
    int zsocket_affinity (void *socket);
    //  Returns freshly allocated string, free when done
    char * zsocket_identity (void *socket);
    int zsocket_rate (void *socket);
    int zsocket_recovery_ivl (void *socket);
    int zsocket_recovery_ivl_msec (void *socket);
    int zsocket_mcast_loop (void *socket);
    #if (ZMQ_VERSION_MINOR == 2)
    int zsocket_rcvtimeo (void *socket);
    #endif
    #if (ZMQ_VERSION_MINOR == 2)
    int zsocket_sndtimeo (void *socket);
    #endif
    int zsocket_sndbuf (void *socket);
    int zsocket_rcvbuf (void *socket);
    int zsocket_linger (void *socket);
    int zsocket_reconnect_ivl (void *socket);
    int zsocket_reconnect_ivl_max (void *socket);
    int zsocket_backlog (void *socket);
    int zsocket_type (void *socket);
    int zsocket_rcvmore (void *socket);
    int zsocket_fd (void *socket);
    int zsocket_events (void *socket);

    //  Set socket options
    void zsocket_set_hwm (void *socket, int hwm);
    void zsocket_set_swap (void *socket, int swap);
    void zsocket_set_affinity (void *socket, int affinity);
    void zsocket_set_identity (void *socket, char * identity);
    void zsocket_set_rate (void *socket, int rate);
    void zsocket_set_recovery_ivl (void *socket, int recovery_ivl);
    void zsocket_set_recovery_ivl_msec (void *socket, int recovery_ivl_msec);
    void zsocket_set_mcast_loop (void *socket, int mcast_loop);
    #   if (ZMQ_VERSION_MINOR == 2)
    void zsocket_set_rcvtimeo (void *socket, int rcvtimeo);
    #   endif
    #   if (ZMQ_VERSION_MINOR == 2)
    void zsocket_set_sndtimeo (void *socket, int sndtimeo);
    #   endif
    void zsocket_set_sndbuf (void *socket, int sndbuf);
    void zsocket_set_rcvbuf (void *socket, int rcvbuf);
    void zsocket_set_linger (void *socket, int linger);
    void zsocket_set_reconnect_ivl (void *socket, int reconnect_ivl);
    void zsocket_set_reconnect_ivl_max (void *socket, int reconnect_ivl_max);
    void zsocket_set_backlog (void *socket, int backlog);
    void zsocket_set_subscribe (void *socket, char * subscribe);
    void zsocket_set_unsubscribe (void *socket, char * unsubscribe);
    #endif

    #if (ZMQ_VERSION_MAJOR == 3)
    //  Get socket options
    int zsocket_type (void *socket);
    int zsocket_sndhwm (void *socket);
    int zsocket_rcvhwm (void *socket);
    int zsocket_affinity (void *socket);
    //  Returns freshly allocated string, free when done
    char * zsocket_identity (void *socket);
    int zsocket_rate (void *socket);
    int zsocket_recovery_ivl (void *socket);
    int zsocket_sndbuf (void *socket);
    int zsocket_rcvbuf (void *socket);
    int zsocket_linger (void *socket);
    int zsocket_reconnect_ivl (void *socket);
    int zsocket_reconnect_ivl_max (void *socket);
    int zsocket_backlog (void *socket);
    int zsocket_maxmsgsize (void *socket);
    int zsocket_multicast_hops (void *socket);
    int zsocket_rcvtimeo (void *socket);
    int zsocket_sndtimeo (void *socket);
    int zsocket_ipv4only (void *socket);
    int zsocket_rcvmore (void *socket);
    int zsocket_fd (void *socket);
    int zsocket_events (void *socket);
    //  Returns freshly allocated string, free when done
    char * zsocket_last_endpoint (void *socket);

    //  Set socket options
    void zsocket_set_sndhwm (void *socket, int sndhwm);
    void zsocket_set_rcvhwm (void *socket, int rcvhwm);
    void zsocket_set_affinity (void *socket, int affinity);
    void zsocket_set_subscribe (void *socket, char * subscribe);
    void zsocket_set_unsubscribe (void *socket, char * unsubscribe);
    void zsocket_set_identity (void *socket, char * identity);
    void zsocket_set_rate (void *socket, int rate);
    void zsocket_set_recovery_ivl (void *socket, int recovery_ivl);
    void zsocket_set_sndbuf (void *socket, int sndbuf);
    void zsocket_set_rcvbuf (void *socket, int rcvbuf);
    void zsocket_set_linger (void *socket, int linger);
    void zsocket_set_reconnect_ivl (void *socket, int reconnect_ivl);
    void zsocket_set_reconnect_ivl_max (void *socket, int reconnect_ivl_max);
    void zsocket_set_backlog (void *socket, int backlog);
    void zsocket_set_maxmsgsize (void *socket, int maxmsgsize);
    void zsocket_set_multicast_hops (void *socket, int multicast_hops);
    void zsocket_set_rcvtimeo (void *socket, int rcvtimeo);
    void zsocket_set_sndtimeo (void *socket, int sndtimeo);
    void zsocket_set_ipv4only (void *socket, int ipv4only);
    void zsocket_set_router_behavior (void *socket, int router_behavior);

    //  Emulation of widely-used 2.x socket options
    void zsocket_set_hwm (void *socket, int hwm);
    #endif

    int zsockopt_test (bool verbose);
    
//  Deprecated function names
#if (ZMQ_VERSION_MAJOR == 2)
#define zsockopt_hwm zsocket_hwm
#define zsockopt_set_hwm zsocket_set_hwm
#define zsockopt_swap zsocket_swap
#define zsockopt_set_swap zsocket_set_swap
#define zsockopt_affinity zsocket_affinity
#define zsockopt_set_affinity zsocket_set_affinity
#define zsockopt_identity zsocket_identity
#define zsockopt_set_identity zsocket_set_identity
#define zsockopt_rate zsocket_rate
#define zsockopt_set_rate zsocket_set_rate
#define zsockopt_recovery_ivl zsocket_recovery_ivl
#define zsockopt_set_recovery_ivl zsocket_set_recovery_ivl
#define zsockopt_recovery_ivl_msec zsocket_recovery_ivl_msec
#define zsockopt_set_recovery_ivl_msec zsocket_set_recovery_ivl_msec
#define zsockopt_mcast_loop zsocket_mcast_loop
#define zsockopt_set_mcast_loop zsocket_set_mcast_loop
#   if (ZMQ_VERSION_MINOR == 2)
#define zsockopt_rcvtimeo zsocket_rcvtimeo
#define zsockopt_set_rcvtimeo zsocket_set_rcvtimeo
#   endif
#   if (ZMQ_VERSION_MINOR == 2)
#define zsockopt_sndtimeo zsocket_sndtimeo
#define zsockopt_set_sndtimeo zsocket_set_sndtimeo
#   endif
#define zsockopt_sndbuf zsocket_sndbuf
#define zsockopt_set_sndbuf zsocket_set_sndbuf
#define zsockopt_rcvbuf zsocket_rcvbuf
#define zsockopt_set_rcvbuf zsocket_set_rcvbuf
#define zsockopt_linger zsocket_linger
#define zsockopt_set_linger zsocket_set_linger
#define zsockopt_reconnect_ivl zsocket_reconnect_ivl
#define zsockopt_set_reconnect_ivl zsocket_set_reconnect_ivl
#define zsockopt_reconnect_ivl_max zsocket_reconnect_ivl_max
#define zsockopt_set_reconnect_ivl_max zsocket_set_reconnect_ivl_max
#define zsockopt_backlog zsocket_backlog
#define zsockopt_set_backlog zsocket_set_backlog
#define zsockopt_set_subscribe zsocket_set_subscribe
#define zsockopt_set_unsubscribe zsocket_set_unsubscribe
#define zsockopt_type zsocket_type
#define zsockopt_rcvmore zsocket_rcvmore
#define zsockopt_fd zsocket_fd
#define zsockopt_events zsocket_events
#endif

//  Deprecated function names
#if (ZMQ_VERSION_MAJOR == 3)
#define zsockopt_type zsocket_type
#define zsockopt_sndhwm zsocket_sndhwm
#define zsockopt_set_sndhwm zsocket_set_sndhwm
#define zsockopt_rcvhwm zsocket_rcvhwm
#define zsockopt_set_rcvhwm zsocket_set_rcvhwm
#define zsockopt_affinity zsocket_affinity
#define zsockopt_set_affinity zsocket_set_affinity
#define zsockopt_set_subscribe zsocket_set_subscribe
#define zsockopt_set_unsubscribe zsocket_set_unsubscribe
#define zsockopt_identity zsocket_identity
#define zsockopt_set_identity zsocket_set_identity
#define zsockopt_rate zsocket_rate
#define zsockopt_set_rate zsocket_set_rate
#define zsockopt_recovery_ivl zsocket_recovery_ivl
#define zsockopt_set_recovery_ivl zsocket_set_recovery_ivl
#define zsockopt_sndbuf zsocket_sndbuf
#define zsockopt_set_sndbuf zsocket_set_sndbuf
#define zsockopt_rcvbuf zsocket_rcvbuf
#define zsockopt_set_rcvbuf zsocket_set_rcvbuf
#define zsockopt_linger zsocket_linger
#define zsockopt_set_linger zsocket_set_linger
#define zsockopt_reconnect_ivl zsocket_reconnect_ivl
#define zsockopt_set_reconnect_ivl zsocket_set_reconnect_ivl
#define zsockopt_reconnect_ivl_max zsocket_reconnect_ivl_max
#define zsockopt_set_reconnect_ivl_max zsocket_set_reconnect_ivl_max
#define zsockopt_backlog zsocket_backlog
#define zsockopt_set_backlog zsocket_set_backlog
#define zsockopt_maxmsgsize zsocket_maxmsgsize
#define zsockopt_set_maxmsgsize zsocket_set_maxmsgsize
#define zsockopt_multicast_hops zsocket_multicast_hops
#define zsockopt_set_multicast_hops zsocket_set_multicast_hops
#define zsockopt_rcvtimeo zsocket_rcvtimeo
#define zsockopt_set_rcvtimeo zsocket_set_rcvtimeo
#define zsockopt_sndtimeo zsocket_sndtimeo
#define zsockopt_set_sndtimeo zsocket_set_sndtimeo
#define zsockopt_ipv4only zsocket_ipv4only
#define zsockopt_set_ipv4only zsocket_set_ipv4only
#define zsockopt_set_router_behavior zsocket_set_router_behavior
#define zsockopt_rcvmore zsocket_rcvmore
#define zsockopt_fd zsocket_fd
#define zsockopt_events zsocket_events
#define zsockopt_last_endpoint zsocket_last_endpoint
#endif
*/
    char * zstr_recv (void *socket);
    char * zstr_recv_nowait (void *socket);
    int zstr_send (void *socket, const char *string);
    int zstr_sendm (void *socket, const char *string);
    int zstr_sendf (void *socket, const char *format, ...);
    int zstr_sendfm (void *socket, const char *format, ...);
    int zstr_test (bool verbose);
    
    alias void * function (void *args) zthread_detached_fn;
    alias void function (void *args, zctx_t *ctx, void *pipe) zthread_attached_fn;
    int zthread_new (zthread_detached_fn *thread_fn, void *args);
    void * zthread_fork (zctx_t *ctx, zthread_attached_fn *thread_fn, void *args);
    int zthread_test (bool verbose);
}

