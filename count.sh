#!/bin/bash

set -e

cd src/
find . -name '*.d' | xargs wc -l
