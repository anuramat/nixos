#!/usr/bin/env bash

stty rows 80 cols 80
expect <(
	cat << EOF
set timeout 1
spawn $*
sleep 1
expect
exit
EOF
) | ansifilter
