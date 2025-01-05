#!/usr/bin/env bash

# deps: fzf opts

command -v zoxide &> /dev/null && eval "$(zoxide init bash --cmd j --hook pwd)" # appends
export _ZO_FZF_OPTS="
--no-sort
--exit-0
--select-1
--preview='$XDG_CONFIG_HOME/bash/fzf_previewer.sh {2..}'
$FZF_DEFAULT_OPTS
"
export _ZO_RESOLVE_SYMLINKS="1"
export _ZO_ECHO=1
export _ZO_EXCLUDE_DIRS="$XDG_CACHE_HOME/*:/nix/store/*"
