#!/bin/bash

dmd src/*.d src/interruption/*.d src/dlog/*.d  src/http/server/*.d src/http/protocol/*.d -ofbin/dhttpd -Isrc/ -L-lcurl -unittest -version=tracing
#dmd zmq.d main.d -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -ofnotajoy
