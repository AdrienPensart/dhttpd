#!/bin/bash

set -e

ragelfile=src/http/protocol/Request.d.rl

dmd_flags=""
if [[ $1 == "release" ]]; then
	dmd_flags="-O -release -noboundscheck -inline"
elif [[ $1 == "release_profiled" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -version=profiling"
elif [[ $1 == "release_dmd_profiled" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -profile -version=dmdprofiling"
elif [[ $1 == "debug" ]]; then
	dmd_flags="-unittest -g -debug -gc -gs -version=profiling"
elif [[ $1 == "graph" ]]; then
	ragel -p -V $ragelfile -o $ragelfile.dot
	dot -Tpng $ragelfile.dot > $ragelfile.png
else
	echo "bad or no argument !"
	exit 0
fi

rageloutput=src/http/protocol/Request.d
tmpfile=/tmp/dhttpd-ragel-request
if [[ ! -f $rageloutput || ! -f $tmpfile || $ragelfile -nt $tmpfile ]]; then
	ragel -G2 -E $ragelfile -o $rageloutput
	touch $tmpfile -r $ragelfile
fi

includes="-Isrc/ -Isrc/libev -Isrc/czmq/deimos -Isrc/msgpack/src"
libraries="-L-luuid -L-lev -L-lstdc++ -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a"
httpdbin="-ofdhttpd"
loggerbin="-oflogger"

#rdmd --build-only $includes $loggerbin $libraries $dmd_flags src/logger.d
dmd $includes $loggerbin $libraries $dmd_flags src/logger.d src/dlog/*.d src/msgpack/src/msgpack.d

#rdmd --build-only $includes $httpdbin $libraries $dmd_flags src/main.d
#dmd $includes $binoutput $libraries $dmd_flags src/main.d src/EventLoop.d src/http/server/*.d src/http/protocol/*.d src/dlog/*.d src/crunch/*.d src/libev/deimos/*.d