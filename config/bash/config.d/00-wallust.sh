#!/usr/bin/env bash

__wallust_cs_dir="$XDG_CONFIG_HOME/wallust/colorschemes"

# set wallust theme, and apply post hooks
__wallust_wrapped() {
	if [ "$1" = "sex" ]; then
		wallust cs -f terminal-sexy "$__wallust_cs_dir/$2.json" || return
	else
		wallust "$@" || return
	fi
	"$XDG_CONFIG_HOME/mako/wal.sh"
	swaymsg reload &> /dev/null || true # shits out a scary error - ignore it TODO figure out
}
