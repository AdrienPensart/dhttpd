#!/bin/bash

dmd src/*.d src/interruption/*.d src/dlog/*.d  src/http/server/*.d src/http/protocol/*.d -ofbin/dhttpd -Isrc/ -L-lcurl -unittest -version=tracing

