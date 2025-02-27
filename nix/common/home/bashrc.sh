#!/usr/bin/env bash

export TERMCMD=foot

export XDG_DOWNLOAD_DIR="$HOME/dl/"
export XDG_DOCUMENTS_DIR="$HOME/docs/"
export XDG_PICTURES_DIR="$HOME/img/"
export XDG_VIDEOS_DIR="$HOME/vid/"

# ssh sessions are hardcoded to source bashrc
# which is a problem when it's actually not an interactive session
# PS1 is hardcoded to be unset in non-interactive sessions
# <https://www.gnu.org/software/bash/manual/bash.html#Is-this-Shell-Interactive_003f>
[ -z "$PS1" ] && return

shopt -s globstar # enables **
set +H            # turn off ! history bullshit

# shellcheck source=config/bash/xdg_shims.sh
source "$XDG_CONFIG_HOME/bash/xdg_shims.sh"
for f in "$XDG_CONFIG_HOME"/bash/config.d/*; do source "$f"; done

alias repl="nixos-rebuild repl"
alias f="nvim"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias peco="fzf --height=100 --preview=''"
alias recv='tailscale file get'
alias d='rmtrash'
alias t="todo"

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
	# uhhh TODO unugly
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
beep() {
	# announce every $1 minutes
	local -r period=$1
	[ -n "$period" ] || {
		echo -e 'Invalid arguments\nUsage:\n\tbeep 45'
		return 1
	}

	while true; do
		local hours=$(date +%H)
		local minutes=$(date +%M)
		(say "Current time: $hours $minutes" &)
		sleep $((period * 60))
	done
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

# vim: fdl=0
