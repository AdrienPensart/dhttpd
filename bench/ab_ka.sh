#!/bin/bash

ab -k -n 100000 -c 100 -H "Server: www.dhttpd.fr" http://127.0.0.1:8080/main/home.html