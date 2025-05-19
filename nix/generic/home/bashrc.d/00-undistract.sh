#!/usr/bin/env bash

export UNDISTRACT_TOLERANCE=5

__undistract_preexec() {
	__undistract_last_command_start_time=$(date +%s)
	__undistract_last_command="$1"
}
preexec_functions+=(__undistract_preexec)

__undistract() {
	[ -z "$__undistract_last_command_start_time" ] && return
	local diff="$(($(date +%s) - __undistract_last_command_start_time))"
	((diff > UNDISTRACT_TOLERANCE)) && [[ $TERM =~ ^(foot)$ ]] && {
		tput bel
		printf "\e]777;notify;%s;%s\e\\" "Executed" "$__undistract_last_command"
	}
	# 777: foot, ghostty
	# 99: foot
	# '\e]99;;%s\e\\'
}
precmd_functions+=(__undistract)
