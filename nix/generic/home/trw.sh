#!/usr/bin/env bash

trw() {
	local -r subcommand=$1 && shift
	local force && [ "$1" = '-f' ] && shift && force=true
	local -r remote=$1
	local -r path=$(realpath "$2")/

	local from=$path
	local to=$remote:$path
	local shortflags=-av
	local longflag=

	case "$subcommand" in
		h)
			echo 'trw down/up/check [-f] $REMOTE $PATH'
			;;
		down)
			temp=$to
			to=$from
			from=$temp
			;&
		up)
			longflag=--ignore-existing
			[ "$force" = true ] && __trw_sure && longflag=--delete || return 1
			;;
		check)
			shortflags+=n
			longflag=--delete
			[ "$force" = true ] && __trw_sure && shortflags+=c || return 1
			;;
		*)
			echo 'illegal subcommand'
			return 1
			;;
	esac

	__trw_check_ends "$remote" "$path" || return 1

	rsync "$shortflags" "$longflag" "$from" "$to"
}

__trw_check_ends() {
	local remote="$1"
	local path
	path="$(realpath -q "$2")/" && [ -n "$path" ] && [ -d "$path" ] || {
		echo "error: invalid path: $path"
		return 1
	}
	[ -n "$remote" ] || {
		echo "error: empty remote"
		return 1
	}
}

__trw_sure() {
	local reply
	echo "are you sure? (y/*)"
	read -t 1 -n 1 -r reply
	echo
	[ "$reply" == y ]
}
