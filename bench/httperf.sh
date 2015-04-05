#!/bin/bash

httperf --hog --server 127.0.0.1 --port 8080 --uri /main/home.html --num-calls 1000 --num-conns 100
