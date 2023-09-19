#!/usr/bin/env bash

alias f="nvim"

if command -v "eza" >/dev/null 2>&1; then
	# config file is proposed:
	alias ls="$EZACMD"
	alias ll="$EZACMD --long"
	alias la="$EZACMD --long --all"
	alias tree="$EZACMD --tree"
else
	alias ll="ls -lth"
	alias la="ls -alth"
fi

alias fd="fd -H"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias conda="micromamba"

alias icat="kitty +kitten icat"

alias nire="sudo nixos-rebuild switch"
alias nied="sudo -e /etc/nixos/configuration.nix"

alias open=xdg-open

alias yarn='yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'
