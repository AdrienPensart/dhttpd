#!/bin/bash

set -e

ragel -G2 -E src/http/protocol/Request.d.rl -o src/http/protocol/Request.d
sources="src/*.d src/dlog/*.d src/http/protocol/*.d src/http/server/*.d src/libev/*.d"
includes="-Isrc/ -Isrc/libev -Isrc/czmq"

#gdc $includes $sources 

libraries="-L-luuid -L-lstdc++ -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -L-lev"
binoutput="-ofdhttpd"
dmd_flags=""

if [[ $1 == "release" ]]; then
	dmd_flags="-O -release -noboundscheck"
elif [[ $1 == "release_profiled" ]]; then
	dmd_flags="-O -release -noboundscheck -profile"
else
	dmd_flags="-unittest -debug -vtls -profile -gc -gs -gx -g"
fi

dmd $sources $includes $binoutput $libraries $dmd_flags

# Graph generation
#ragel -p -V src/HttpParsing.d.rl -o src/HttpParsing.dot
#dot -Tpng src/HttpParsing.dot > src/HttpParsing.png
