#!/bin/bash

set -e

if [[ ! -f utils/profile ]]; then
    utils/build.sh
fi

if [[ $1 == "release" ]]; then
    if [[ ! -f dhttpd ]]; then
        ./build.sh release
    fi
    ./dhttpd
fi

utils/profile trace.log

