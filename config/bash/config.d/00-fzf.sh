#!/usr/bin/env bash

default_preview="--preview='$XDG_CONFIG_HOME/bash/fzf_previewer.sh {}'"
if command -v "fd" &> /dev/null; then
	export FZF_DEFAULT_COMMAND="fd -u --exclude .git/"

	export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND -t d"
	export FZF_ALT_C_OPTS="$default_preview"

	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_CTRL_T_OPTS="$default_preview"
fi
