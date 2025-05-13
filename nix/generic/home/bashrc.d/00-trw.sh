#!/usr/bin/env bash

trw() {
	local -r errstr='error: %s\nusage: trw (check/sync) (up/down) [force] HOSTNAME PATH\n'

	((5 >= $#)) && (($# >= 4)) || {
		printf "$errstr" 'illegal number of arguments'
		return 1
	}

	local -r subcommand=$1 && shift
	local -r direction=$1 && shift

	local force=false
	[ "$#" = 3 ] && {
		[ "$1" != 'force' ] && {
			printf "$errstr" "illegal flag: $1"
			return 1
		}
		force=true && shift
	}

	local -r remote=$1
	[ -n "$remote" ] || {
		printf "$errstr" "empty hostname"
		return 1
	}

	local path
	path=$(realpath -q "$2")/ && [ -d "$path" ] || {
		printf "$errstr" "invalid path: $path"
		return 1
	}

	local shortflags=-av
	local longflag=
	case "$subcommand" in
		sync)
			longflag=--ignore-existing
			[ "$force" = true ] && longflag=--delete
			;;
		check)
			shortflags+=n
			longflag=--delete
			[ "$force" = true ] && shortflags+=c
			;;
		*)
			printf "$errstr" 'illegal subcommand'
			return 1
			;;
	esac

	case "$direction" in
		up)
			local from=$path
			local to=$remote:$path
			;;
		down)
			local from=$remote:$path
			local to=$path
			;;
		*)
			printf "$errstr" 'illegal direction'
			return 1
			;;
	esac

	local -r args=("$shortflags" "$longflag" "$from" "$to")

	printf 'executing: rsync %s\n' "${args[*]}"
	local reply
	echo "continue? (y/*)"
	read -n 1 -r reply
	echo
	[ "$reply" != y ] && return 1

	rsync "${args[@]}"
}
