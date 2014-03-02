#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

dmd $DIR/profiler.d -of$DIR/profiler -release

