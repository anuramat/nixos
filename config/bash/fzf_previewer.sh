#!/usr/bin/env bash

# directory
if [ -d "$1" ]; then
	# directory: eza > tree > ls
	if command -v "eza" &> /dev/null; then
		# $EZACMD --tree "$1"
		$EZACMD --grid "$1"
		exit
	fi
	if command -v "tree" &> /dev/null; then
		tree -C "$1"
		exit
	fi
	ls -a "$1"
	exit
# file
elif [ -f "$1" ]; then
	# image
	timg -p s "-g${FZF_PREVIEW_COLUMNS}x$FZF_PREVIEW_LINES" $1 && exit
	# plaintext
	if command -v "bat" &> /dev/null; then
		bat --style=numbers --color=always "$1" && exit
	fi
	cat "$1" && exit
fi
