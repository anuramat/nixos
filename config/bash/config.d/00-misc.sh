#!/usr/bin/env bash

export SCREENSHOT_DIR="$HOME/img/screen"
mkdir -p "$SCREENSHOT_DIR"

# eza
export EZACMD="eza --group-directories-first --group --header --git --icons=always --color=always --color-scale=all --sort=time"
if command -v "eza" &> /dev/null; then
	# config file implementation is in progress:
	# https://github.com/eza-community/eza/issues/897
	alias ls="$EZACMD"
	alias ll="$EZACMD --long"
	alias la="$EZACMD --long --all"
	alias tree="$EZACMD --tree"
	alias treedir="$EZACMD --tree --only-dirs"
else
	alias ls="ls --color=auto"
	alias ll="ls -lth --color=auto"
	alias la="ls -alth --color=auto"
fi

# colorize some basic stuff
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip -c=auto'

# etc
# TODO move this shit
alias fd="fd -HI --exclude .git" # everything but .git
alias info="info --init-file $XDG_CONFIG_HOME/infokey"
export GRIM_DEFAULT_DIR="$SCREENSHOT_DIR"
export VIRTUAL_ENV_DISABLE_PROMPT="1" # TODO maybe we don't need this either? # Don't let python venvs change the PS1
export VIMTEX_OUTPUT_DIRECTORY="/tmp/"
export NO_AT_BRIDGE=1 # TODO do we still need this # hides gnomeWARNING **: Couldn't connect to accessibility bus:
