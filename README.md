# dhttpd

Another HTTP server (WARNING : not for production :D)

## Features

* Evented (100000 simultaneous requests)
* Benchmarks scripts (AB, HTTPerf)

## Objectives

* learn ZMQ framework
* learn the HTTP protocol
* mastering D language
* learn evented networking
* use dlog, a logging framework written in D
* learn execution tracing / optimization / profiling

## Dependencies

* xxhash
* msgpack
* zmq/czmq/zmqd/zapi
* openssl
* libev
* ragel, for HTTP protocol parsing
* valgrind / kcachegrind for profiling

