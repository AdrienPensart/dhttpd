#!/bin/bash

set -e

ragelfile=src/http/protocol/Request.d.rl

dmd_flags=""
if [[ $1 == "release" ]]; then
	dmd_flags="-O -release -noboundscheck -inline"
elif [[ $1 == "release_unittest" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -unittest"
elif [[ $1 == "release_profile" ]]; then
	dmd_flags="-release -profile"
elif [[ $1 == "release_info" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -gs -g -gc"
elif [[ $1 == "release_autoprofile" ]]; then
	dmd_flags="-O -release -noboundscheck -inline -version=autoprofile"
elif [[ $1 == "debug" ]]; then
	dmd_flags="-g -debug -gc -gs"
elif [[ $1 == "analysis" ]]; then
	dmd_flags="-g -release -gc -gs"
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

# experiment, use gold linker : -L-fuse-ld=gold -L-L/usr/local/lib

rageloutput=src/http/protocol/Request.d
tmpfile=/tmp/dhttpd-ragel-request
if [[ ! -f $rageloutput || ! -f $tmpfile || $ragelfile -nt $tmpfile ]]; then
	ragel -G2 -E $ragelfile -o $rageloutput
	touch $tmpfile -r $ragelfile
fi

includes="-Isrc/ -Isrc/libev -Isrc/czmq/deimos -Isrc/msgpack/src -Isrc/xxhash/src"
libraries="-L-luuid -L-lev -L-lstdc++ -L-lczmq -L-lzmq -Lsrc/xxhash/libxxhash.a"

loggersrc="src/logger.d src/dlog/*.d src/msgpack/src/msgpack.d src/czmq/deimos/*.d"
#dmd $includes $libraries $dmd_flags $loggersrc
#ldmd2 $includes $libraries $dmd_flags $loggersrc
rdmd --build-only -ofbin/logger $includes $libraries $dmd_flags src/logger.d
#gdc -o bin/logger $includes $libraries $loggersrc

dhttpdsrc="src/dhttpd.d src/loop/* src/msgpack/src/msgpack.d src/http/*.d src/http/protocol/*.d src/dlog/*.d src/crunch/*.d src/libev/deimos/*.d src/czmq/deimos/*.d"
#dmd $includes $libraries $dmd_flags $dhttpdsrc
rdmd --build-only -ofbin/dhttpd $includes $libraries $dmd_flags src/dhttpd.d

rdmd --build-only -ofbin/profile -release -O src/profile.d
