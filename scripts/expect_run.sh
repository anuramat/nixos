#!/usr/bin/env bash

expect <(
	cat << EOF
spawn $*
set timeout 1
sleep 1
expect
exit
EOF
) | ansifilter
