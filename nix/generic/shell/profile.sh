#!/bin/sh

# some basic env vars
# TODO: read this:
# https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html

# XDG paths
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# not part of the spec yet
export XDG_BIN_HOME="$HOME/.local/bin"
export PATH="$XDG_BIN_HOME${PATH:+:$PATH}"

# just in case
export LC_ALL="en_US.UTF-8"
export PAGER=less
export MANPAGER=less

for editor in nvim vim nvi vi; do
	if command -v "$editor" > /dev/null 2>&1; then
		export VISUAL="$editor"
		export EDITOR="$editor"
		break
	fi
done
