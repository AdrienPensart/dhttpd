#!/bin/bash

git submodule init
git submodule update
sudo apt-get install ragel uuid-dev libzmq3-dev libev-dev libtool autoconf pkg-config

# building czmq C binding
cd src/zapi
sh autogen.sh
sh configure
make
sudo make install
cd -

# building xxhash lib
#cd src/xxhash
#make -f posix.mak
#cd -

