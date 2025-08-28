#!/usr/bin/env bash

shopt -s globstar # enables **
set +H            # turn off ! history bullshit

gwipe() {
	git worktree list --porcelain -z | grep -z worktree | cut -zd ' ' -f 2 | grep -vzxF "$PWD" | xargs -0I{} git worktree remove '{}'
}

upload() {
	# uploads a file, sends link to stdout AND clipboard
	local filename="$1"
	[ "$1" = "" ] && filename="-"
	curl -F "file=@$filename" https://0x0.st | tee >(wl-copy)
}

z() {
	if [[ $1 =~ \.md$ ]]; then
		hotdoc "$@"
		exit
	fi
	zathura "$@" &>/dev/null &
	disown
}

take() {
	# send full path of a file/files to clipboard
	local paths=()
	for i in "$@"; do
		paths+=("$(printf %q "$(realpath "$i")")")
	done
	echo "${paths[@]}" | wl-copy -n
}

brexit() {
	# set brightness for an external monitor (0-100)
	# usage: brexit 69
	ddcutil setvcp 10 "$1" --display 1
}

nai() {
	path=$(realpath "$(command -v "$1")")
	cd "$(echo "$path" | cut -d / -f 1-4)" || {
		echo "not found"
		return 1
	}
}
