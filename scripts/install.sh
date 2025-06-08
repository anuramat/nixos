#!/usr/bin/env bash
set -e

LINKDIR=$(realpath "$1")

lndir() (
	source="$1"
	directory="$2"
	printf "$2: %s\n" "$(find "$1" -maxdepth 1 -mindepth 1 | xargs -n 1 basename | tr '\n' ' ')"
	[ -z "$directory" ] && {
		echo "can't link $1: target not set"
		return 1
	}
	shopt -s dotglob
	mkdir -p "$directory"
	ln -sft "$directory" "$source"/*
	shopt -u dotglob
)

source "$HOME/.profile"
lndir "$LINKDIR/config" "$XDG_CONFIG_HOME"
lndir "$LINKDIR/bin" "$XDG_BIN_HOME"
lndir "$LINKDIR/home" "$HOME"
