#!/usr/bin/env bash

usage="usage: $0 <host> { up | down } <options> <path>"

rs() {
	local host direction path
	host=$1 && shift
	direction=$1 && shift
	path=$(realpath -- "${*: -1:1}")
	[ -d "$path" ] || {
		echo 'error: path is not a directory or it does not exist'
		echo "$usage"
		return 1
	}
	local args=("${@:1:$#-1}")
	case "$direction" in
		down)
			from="$host:$path"
			to="$path"
			;;
		up)
			from="$path"
			to="$host:$path"
			;;
		*)
			echo "$usage"
			return 1
			;;
	esac

	rsync "${args[@]}" "$from/" "$to/"
}

rs "$@"
