#!/bin/bash

ragel -E src/http/protocol/Parser.d.rl -o src/http/protocol/Parser.d
dmd src/*.d src/interruption/*.d src/dlog/*.d  src/http/protocol/*.d src/http/server/*.d -ofbin/dhttpd -Isrc/ -L-lcurl -unittest -version=tracing
#dmd zmq.d main.d -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -ofnotajoy

# Graph generation
#ragel -p -V src/HttpParsing.d.rl -o src/HttpParsing.dot
#dot -Tpng src/HttpParsing.dot > src/HttpParsing.png
