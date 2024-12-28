#!/usr/bin/env bash

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
pandoc-md() {
	# md to pdf
	# usage: c i.md o.pdf
	__markdown=markdown+lists_without_preceding_blankline+mark+wikilinks_title_after_pipe+citations
	pandoc --pdf-engine xelatex -H "$XDG_CONFIG_HOME/latex/preamble.tex" "$1" --citeproc -f "$__markdown" -t pdf -o "$2"
}
hotdoc() {
	# renders $1.md to pdf, opens in zathura, rerenders on save
	# usage: hotdoc target.md

	__markdown=markdown+lists_without_preceding_blankline+mark+wikilinks_title_after_pipe+citations

	# create file
	local -r path="$(mktemp -p /tmp XXXXXX.pdf)"
	# initialize it with a basic pdf so that zathura doesn't shit itself
	echo 'JVBERi0xLgoxIDAgb2JqPDwvUGFnZXMgMiAwIFI+PmVuZG9iagoyIDAgb2JqPDwvS2lkc1szIDAgUl0vQ291bnQgMT4+ZW5kb2JqCjMgMCBvYmo8PC9QYXJlbnQgMiAwIFI+PmVuZG9iagp0cmFpbGVyIDw8L1Jvb3QgMSAwIFI+Pg==' \
		| base64 -d > "$path"

	# open zathura
	zathura "$path" &> /dev/null &
	local -r zathura_pid="$!"

	# start watching for changes
	(export -f pandoc-md && echo "$1" | entr -cns "pandoc-md \"$1\" \"$path\"") &
	local -r entr_pid="$!"

	# kill entr if zathura is closed
	wait "$zathura_pid"
	kill "$entr_pid"

	# clean up
	rm "$path"
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
	path=$(realpath "$(command -v $1)")
	cd "$(echo "$path" | cut -d / -f 1-4)" || {
		echo "not found"
		return 1
	}
}

# vim: fdl=0
