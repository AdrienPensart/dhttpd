#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

dmd $DIR/profile.d -of$DIR/profile -release

