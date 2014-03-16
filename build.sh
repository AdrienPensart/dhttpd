#!/bin/bash

set -e

ragelfile=src/http/protocol/Request.d.rl

dmd_flags=""
if [[ $1 == "release" ]]; then
	dmd_flags="-O -release -noboundscheck -inline"
elif [[ $1 == "release_unittest" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -unittest"
elif [[ $1 == "release_profile" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -profile"
elif [[ $1 == "release_autoprofile" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -version=autoprofile"
elif [[ $1 == "debug" ]]; then
	dmd_flags="-g -debug -gc -gs"
elif [[ $1 == "debug_unittest" ]]; then
	dmd_flags="-unittest -g -debug -gc -gs"
elif [[ $1 == "debug_profile" ]]; then
	dmd_flags="-g -debug -gc -gs -profile"
elif [[ $1 == "debug_autoprofile" ]]; then
	dmd_flags="-g -debug -gc -gs -version=autoprofile"
elif [[ $1 == "graph" ]]; then
	echo "Ragel graph generation..."
	ragel -p -V $ragelfile -o $ragelfile.dot
	dot -Tpng $ragelfile.dot > $ragelfile.png
	exit 0
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
libraries="-L-luuid -L-lev -L-lstdc++ -L-lczmq -L-lzmq"

#loggersrc="src/logger.d src/dlog/*.d src/msgpack/src/msgpack.d src/czmq/deimos/*.d"
#dmd $includes $loggerbin $libraries $dmd_flags $loggersrc
rdmd --build-only -oflogger $includes $libraries $dmd_flags src/logger.d

#dhttpdsrc="src/main.d src/EventLoop.d src/msgpack/src/msgpack.d src/http/server/*.d src/http/protocol/*.d src/dlog/*.d src/crunch/*.d src/libev/deimos/*.d src/czmq/deimos/*.d"
#dmd $includes $dhttpdbin $libraries $dmd_flags $dhttpdsrc
rdmd --build-only -ofdhttpd $includes $libraries $dmd_flags src/dhttpd.d
