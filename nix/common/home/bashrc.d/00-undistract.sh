#!/usr/bin/env bash

export UNDISTRACT_TOLERANCE=5 # TODO turn on once kitty is figured out

__undistract_preexec() {
	__last_command_start_time=$(date +%s)
	__last_command="$1"
}
preexec_functions+=(__undistract_preexec)

__undistract() {
	[ -z "$__last_command_start_time" ] && return
	local diff="$(($(date +%s) - __last_command_start_time))"
	((diff > UNDISTRACT_TOLERANCE)) && tput bel && printf "\e]777;notify;%s;%s\e\\" "Executed" "$__last_command"
	# 777: foot, ghostty
	# 99: foot
	# '\e]99;;%s\e\\'
}
precmd_functions+=(__undistract)
