#!/bin/bash

#dmd src/*.d src/interruption/*.d src/dlog/*.d  src/http/server/*.d src/http/protocol/*.d -ofbin/dhttpd -Isrc/ -L-lcurl -unittest -version=tracing
#dmd zmq.d main.d -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -ofnotajoy

#ragel -V http.d.rl -o http.dot

ragel -E src/HttpParser.d.rl -o src/HttpParser.d
dmd src/HttpParser.d src/main2.d

# dot -Tpng http.dot > http.png
