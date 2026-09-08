#!/usr/bin/env bash

pid=$1
[[ -z $pid ]] && echo "usage: $0 $pid"
ps -p "$pid" -o ppid=
