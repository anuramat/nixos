#!/usr/bin/env bash

export XDG_DOWNLOAD_DIR="$HOME/dl/"
export XDG_DOCUMENTS_DIR="$HOME/docs/"
export XDG_PICTURES_DIR="$HOME/img/"
export XDG_VIDEOS_DIR="$HOME/vid/"

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

y() {
	# wrapper that cds to yazi cwd on exit
	local tmp cwd
	tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ "$cwd" != "" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd" || return
	fi
	rm -f -- "$tmp"
}

run() {
	local -r name="$1"
	shift
	nix run "nixpkgs-unstable#$name" -- "$@"
}

shell() {
	local -r name="$1"
	shift
	nix shell "nixpkgs-unstable#$name" -- "$@"
}

# vim: fdl=0
