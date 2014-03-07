#!/bin/bash

siege -t10S -b -H "Server: www.dhttpd.fr" http://127.0.0.1:8080/main/0.html
