#!/bin/bash

set -e

ragel -G2 -E src/http/protocol/Request.d.rl -o src/http/protocol/Request.d
sources="src/*.d src/crunch/* src/dlog/*.d src/http/protocol/*.d src/http/server/*.d src/libev/*.d"
includes="-Isrc/"
# -Isrc/czmq

#gdc $includes $sources 

libraries="-L-luuid -L-lev"
# -L-lstdc++ -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a
binoutput="-ofdhttpd"
dmd_flags=""

if [[ $1 == "release" ]]; then
	dmd_flags="-O -release -noboundscheck -inline"
elif [[ $1 == "release_profiled" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -version=profiling"
elif [[ $1 == "release_dmd_profiled" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -profile -version=dmdprofiling"
elif [[ $1 == "debug" ]]; then
	dmd_flags="-unittest -g -debug -gc -gs -version=profiling"
else
	echo "no argument !"
	exit 0
fi

#rdmd --dry-run $sources $includes $binoutput $libraries $dmd_flags
#rdmd            $sources $includes $binoutput $libraries $dmd_flags
dmd $sources $includes $binoutput $libraries $dmd_flags

# Graph generation
#ragel -p -V src/HttpParsing.d.rl -o src/HttpParsing.dot
#dot -Tpng src/HttpParsing.dot > src/HttpParsing.png
