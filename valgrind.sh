#!/bin/bash

set -e

valgrind --tool=callgrind --dump-instr=yes --simulate-cache=yes --collect-jumps=yes ./dhttpd

