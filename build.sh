#!/bin/bash

sources="src/*.d src/interruption/*.d src/dlog/*.d  src/http/protocol/*.d src/http/server/*.d"
includes="-Isrc/ -Isrc/czmq"
libraries="-L-luuid -L-lstdc++ -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -L-lcurl"
binoutput="-ofdhttpd"
flags=""
ragel_flags=""

if [[ $1 == "release" ]]; then
	flags="-O -release -vtls"
	ragel_flags="-G2"
else
	flags="-unittest -debug -vtls"
fi

ragel -E src/http/protocol/Request.d.rl -o src/http/protocol/Request.d
dmd $sources $includes $binoutput $libraries $flags

# Graph generation
#ragel -p -V src/HttpParsing.d.rl -o src/HttpParsing.dot
#dot -Tpng src/HttpParsing.dot > src/HttpParsing.png
