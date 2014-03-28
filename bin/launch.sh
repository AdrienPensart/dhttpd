#!/bin/bash

if [ "$#" != "2" ]; then
    echo "Usage: launch.sh number_of_processes threads_per_process"
    exit 1
fi

killall -q -s SIGINT dhttpd

set -xe

for i in `seq $1`; do
    ./dhttpd --t=$2 &
done
