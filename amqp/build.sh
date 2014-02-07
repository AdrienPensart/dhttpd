#!/bin/bash

dmd Zmq.d Log.d main.d -L/usr/local/lib/libczmq.a -L/usr/local/lib/libzmq.a -ofnotajoy

