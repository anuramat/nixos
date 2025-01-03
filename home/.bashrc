#!/usr/bin/env bash

# make remote shells obey the fucking rules
[ -z "$PS1" ] && return

shopt -s globstar # enables **
set +H            # turn off ! history bullshit

for f in "$XDG_CONFIG_HOME"/bash/config.d/*; do source "$f"; done

# TODO do I need it? foot is styled already via templates
# # color rice:
# [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ] && [[ $TERM != foot ]] && (cat ~/.cache/wallust/sequences &)

alias f="nvim"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias peco="fzf --height=100 --preview=''"
alias lab="jupyter-lab --ServerApp.iopub_msg_rate_limit 9999999999999"
alias recv='tailscale file get'

alias t="todo.sh"
__load_completion todo.sh
complete -F _todo t

send() {
	# send a file over taildrop:
	# send $file $device:
	tailscale file cp "$@"
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
	zathura "$1" &> /dev/null &
	disown
}
take() {
	# send full path of a file/files to clipboard
	realpath "$@" | tr '\n' ' ' | wl-copy -n
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

# vim: fdl=0
