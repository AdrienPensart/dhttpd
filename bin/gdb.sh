#!/bin/bash

set -e

(echo run ; cat) | gdb -iex "handle SIGPIPE nostop" --args ./dhttpd $@
