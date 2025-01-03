#!/usr/bin/env bash

# bash-completions sets up a default comp func, that lazy-loads completions if
# they exist. fzf defines another default comp func on top, that lazily wraps
# the existing completion, adding "**". note that fzf can't auto-wrap non-lazy
# completions, since it only works with defaults, thus we load everything
# manually. note that for some commands, fzf comp is explicitly defined.
# TODO move/copy this to the notes

__wallust_alias=wal
__load_completion wallust
__wallust_comp_custom() {
	[ "${COMP_WORDS[1]}" = "sex" ] && {
		[ "$COMP_CWORD" = 2 ] && {
			__wallust_cs_dir="$XDG_CONFIG_HOME/wallust/colorschemes"
			mapfile -t sexthemes < <(compgen -W "$(find "$__wallust_cs_dir" -mindepth 1 -exec basename "{}" ';' | sed 's/\.json$//')" ${COMP_WORDS[2]})
			COMPREPLY+=("${sexthemes[@]}") && return
		}
		return
	}
	_wallust "$@"
	[ "$COMP_CWORD" = 1 ] && {
		pot=$(compgen -W sex "${COMP_WORDS[1]}")
		[ -n "$pot" ] && COMPREPLY+=("$pot")
	}
}
complete -o bashdefault -o default -o nosort -F __wallust_comp_custom "$__wallust_alias"
_fzf_setup_completion path "$__wallust_alias"
alias "$__wallust_alias=__wallust_wrapped"
