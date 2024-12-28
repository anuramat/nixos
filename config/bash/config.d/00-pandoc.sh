#!/usr/bin/env bash

__markdown=markdown+wikilinks_title_after_pipe+short_subsuperscripts+mark
# mark: ==highlighted text==
# short_superscripts: x^2, O~2

pandoc-md() {
	# md -> pdf
	# usage: $0 $input $output
	pandoc --pdf-engine xelatex -H "$XDG_CONFIG_HOME/latex/preamble.tex" "$1" --citeproc -f "$__markdown" -t pdf -o "$2"
}

hotdoc() {
	# renders $1.md to pdf, opens in zathura, rerenders on save
	# usage: $0 $target

	# create file
	local -r path="$(mktemp -p /tmp XXXXXXXX.pdf)"
	# initialize it with a basic pdf so that zathura doesn't shit itself
	echo 'JVBERi0xLgoxIDAgb2JqPDwvUGFnZXMgMiAwIFI+PmVuZG9iagoyIDAgb2JqPDwvS2lkc1szIDAgUl0vQ291bnQgMT4+ZW5kb2JqCjMgMCBvYmo8PC9QYXJlbnQgMiAwIFI+PmVuZG9iagp0cmFpbGVyIDw8L1Jvb3QgMSAwIFI+Pg==' \
		| base64 -d > "$path"

	# open zathura
	zathura "$path" &> /dev/null &
	local -r zathura_pid="$!"

	# start watching, recompile on change
	export -f pandoc-md
	(echo "$1" | entr -cns "pandoc-md \"$1\" \"$path\"") &
	local -r entr_pid="$!"

	# stop watching if zathura is closed
	wait "$zathura_pid"
	kill "$entr_pid"

	# clean up
	rm "$path"
}
