#!/usr/bin/env bash

rs() {
	local -r errmsg="error: %s\nusage: $0 <host> { up | down } <options> <path>\n"
	local host=$1 && shift
	local direction=$1 && shift
	local path=$(realpath -- "${*: -1:1}")
	[ -d "$path" ] || {
		printf "$errmsg" 'path does not exist'
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
			printf "$errmsg" "invalid direction"
			return 1
			;;
	esac

	rsync "${args[@]}" "$from/" "$to/"
}

rs "$@"
