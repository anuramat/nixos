#!/usr/bin/env sh

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

trw_up_delete_extra() {
	__trw_check_args "$@" || return 1
	target="$1"
	path="$(realpath "$2")/"
	rsync -av --delete --ignore-existing "$path" "$target:$path"
}

trw_check() {
	__trw_check_args "$@" || return 1
	target="$1"
	path="$(realpath "$2")/"
	rsync -avn --delete "$path" "$target:$path"
}

__trw_check_args() {
	target="$1"
	path="$(realpath -q "$2")/" && [ -n "$target" ] && [ -n "$path" ] && [ -d "$path" ] || {
		echo "invalid arguments"
		return 1
	}
}
