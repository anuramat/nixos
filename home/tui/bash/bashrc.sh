#!/usr/bin/env bash

export TERMCMD=foot

export XDG_DOWNLOAD_DIR="$HOME/dl/"
export XDG_DOCUMENTS_DIR="$HOME/docs/"
export XDG_PICTURES_DIR="$HOME/img/"
export XDG_VIDEOS_DIR="$HOME/vid/"

export ESCDELAY=25

shopt -s globstar # enables **
set +H            # turn off ! history bullshit

alias f="nvim"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias peco="fzf --height=100 --preview=''"
export AI_PROVIDER='pollinations'

send() {
	# send a file over taildrop:
	# send $file $device:
	tailscale file cp "$1" "$2:"
}
upload() {
	# uploads a file, sends link to stdout AND pastebin
	local filename="$1"
	[ -z "$1" ] && filename="-"
	curl -F "file=@$filename" https://0x0.st | tee >(wl-copy)
}
random() {
	# random alnum string
	# usage: random $n
	shuf -er -n "$1" {a..z} {0..9} | tr -d '\n'
}
z() {
	if [[ $1 =~ \.md$ ]]; then
		hotdoc "$@"
		exit
	fi
	zathura "$@" &> /dev/null &
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
exer_dl() {
	# usage: exer_dl lang
	# very shady, might break
	[ -z "$1" ] && echo "specify language" && return
	local lang="$1"
	curl -LS "https://exercism.io/tracks/$lang/exercises" \
		| rg "/tracks/$lang/exercises/([\w-]+\w)" -r '$1' -o \
		| xargs -n 1 -P 10 -I{} sh -c "exercism download --track $lang --force  --exercise {} || true"
}
y() {
	# wrapper that cds to yazi cwd on exit
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd" || return
	fi
	rm -f -- "$tmp"
}

run() {
	local -r name=$1
	shift
	nix run "nixpkgs-unstable#$name" -- "$@"
}

shell() {
	local -r name=$1
	shift
	nix shell "nixpkgs-unstable#$name" -- "$@"
}

# vim: fdl=0
