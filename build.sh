#!/bin/bash

#dmd src/*.d src/interruption/*.d src/dlog/*.d  src/http/server/*.d src/http/protocol/*.d -ofbin/dhttpd -Isrc/ -L-lcurl -unittest -version=tracing
#dmd zmq.d main.d -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -ofnotajoy

#ragel -p -V src/HttpParsing.d.rl -o src/HttpParsing.dot

ragel -E src/HttpParsing.d.rl -o src/HttpParsing.d
dmd src/HttpParsing.d src/main2.d -unittest -ofbin/HttpParsing

#dot -Tpng src/HttpParsing.dot > src/HttpParsing.png
