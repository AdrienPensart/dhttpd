#!/bin/bash

ab -n 100000 -c 100 -H "Connection: close" -H "Host: www.dhttpd.fr" http://127.0.0.1:8080/main/home.html
