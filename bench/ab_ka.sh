#!/bin/bash

ab -k -n 300000 -c 100 -H "Host: www.dhttpd.fr" http://127.0.0.1:8080/main/home.html
