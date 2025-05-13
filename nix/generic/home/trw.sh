#!/usr/bin/env bash

trw_up() {
	__trw_check_args "$@" || return 1
	target="$1"
	path="$(realpath "$2")/"
	rsync -av --ignore-existing "$path" "$target:$path"
}

trw_down() {
	__trw_check_args "$@" || return 1
	target="$1"
	path="$(realpath "$2")/"
	rsync -av --ignore-existing "$target:$path" "$path"
}

trw_up_force() {
	__trw_check_args "$@" || return 1
	target="$1"
	path="$(realpath "$2")/"

	read -p "are you sure?" -n 1 -r REPLY
	[ "$REPLY" != y ] && return 1

	rsync -av --delete "$path" "$target:$path"
}

trw_check() {
	__trw_check_args "$@" || return 1
	target="$1"
	path="$(realpath "$2")/"
	rsync -avn --delete "$path" "$target:$path"
}

trw_check_full() {
	__trw_check_args "$@" || return 1
	target="$1"
	path="$(realpath "$2")/"
	rsync -avnc --delete "$path" "$target:$path"
}

__trw_check_args() {
	target="$1"
	path="$(realpath -q "$2")/" && [ -n "$target" ] && [ -n "$path" ] && [ -d "$path" ] || {
		echo "invalid arguments"
		return 1
	}
}
