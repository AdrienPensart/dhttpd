#!/bin/bash

set -e

valgrind --callgrind-out-file=dhttpd.callgrind.out --tool=callgrind --dump-instr=yes --simulate-cache=yes --collect-jumps=yes --collect-systime=yes ./dhttpd
rm -f dhttpd.callgrind.demangled.out
ddemangle dhttpd.callgrind.out > dhttpd.callgrind.demangled.out
rm dhttpd.callgrind.out
