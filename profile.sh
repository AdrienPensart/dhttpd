#!/bin/bash

set -e

if [[ ! -f protfiler/profiler ]]; then
    profiler/build.sh
fi

rm dhttpd
./build.sh $1

rm trace.*   
./dhttpd
profiler/profiler trace.log
