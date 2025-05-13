#!/usr/bin/env bash

trw() {
	local -r errstr='error: %s\nusage: trw down/up/check [-f] $REMOTE $PATH\n'

	((4 >= $#)) && (($# >= 3)) || {
		printf "$errstr" 'illegal number of arguments'
		return 1
	}

	local -r subcommand=$1 && shift

	local force=false
	[ "$#" = 3 ] && {
		[ "$1" != '-f' ] && {
			printf "$errstr" "illegal flag: $1"
			return 1
		}
		force=true && shift
	}

	local -r remote=$1
	[ -n "$remote" ] || {
		printf "$errstr" "empty remote"
		return 1
	}

	local path
	path=$(realpath -q "$2")/ && [ -d "$path" ] || {
		printf "$errstr" "invalid path: $path"
		return 1
	}

	local from=$path
	local to=$remote:$path
	local shortflags=-av
	local longflag=

	case "$subcommand" in
		down)
			local tmp=$to
			to=$from
			from=$tmp
			;&
		up)
			longflag=--ignore-existing
			[ "$force" = true ] && {
				local reply
				echo "are you sure? (y/*)"
				read -n 1 -r reply
				echo
				[ "$reply" != y ] && return 1
				longflag=--delete
			}
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

	rsync "$shortflags" "$longflag" "$from" "$to"
}
