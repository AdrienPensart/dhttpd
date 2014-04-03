#!/bin/bash

set -e

rm -f trace.*
./dhttpd --console
./profile trace.log
