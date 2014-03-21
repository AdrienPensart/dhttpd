#!/bin/bash

httperf --hog --server www.dhttpd.fr --port 8080 --uri /main/home.html --num-calls 100000 --num-conns 100
