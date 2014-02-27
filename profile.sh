#!/bin/bash

set -e

if [[ ! -f utils/profile ]]; then
    utils/build.sh
fi

rm dhttpd
./build.sh $1

rm trace.*   
./dhttpd
utils/profile trace.log
