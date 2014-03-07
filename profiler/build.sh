#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

dmd $DIR/profiler.d -of$DIR/profiler -release

#valgrind --tool=callgrind --dump-instr=yes --simulate-cache=yes --collect-jumps=yes program arguments