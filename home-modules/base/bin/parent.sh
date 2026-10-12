#!/usr/bin/env bash

pid=${1-}
[[ -z $pid ]] && {
	echo "usage: $0 <pid>" >&2
	exit 1
}
ps -p "$pid" -o ppid=
