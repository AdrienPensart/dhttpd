#!/bin/bash

ragel -E src/http/protocol/Request.d.rl -o src/http/protocol/Request.d

if [[ $1 == "release" ]]; then
	dmd src/*.d src/interruption/*.d src/dlog/*.d  src/http/protocol/*.d src/http/server/*.d -ofdhttpd -Isrc/ -Isrc/czmq -L-lcurl -O -release -vtls
else
	dmd src/*.d src/interruption/*.d src/dlog/*.d  src/http/protocol/*.d src/http/server/*.d -ofdhttpd -Isrc/ -Isrc/czmq -L-lcurl -unittest -debug -vtls
fi

#dmd zmq.d main.d -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -ofnotajoy

# Graph generation
#ragel -p -V src/HttpParsing.d.rl -o src/HttpParsing.dot
#dot -Tpng src/HttpParsing.dot > src/HttpParsing.png
