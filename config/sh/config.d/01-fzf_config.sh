#!/usr/bin/env bash
if command -v "fd" >/dev/null 2>&1; then
	export FZF_DEFAULT_COMMAND="fd ."
	export FZF_ALT_C_COMMAND="fd . -t d --strip-cwd-prefix"
	export FZF_CTRL_T_COMMAND="fd . -t f --strip-cwd-prefix"
fi
export FZF_DEFAULT_OPTS="
--preview='$XDG_CONFIG_HOME/bash/fzf_previewer.sh {}'
--layout=reverse
--keep-right
--info=inline
--tabstop=2
--multi
--height=50%

--bind='ctrl-/:change-preview-window(down|hidden|)'
--bind='ctrl-j:accept'
--bind='tab:toggle+down'
--bind='btab:toggle+up'

--bind='ctrl-y:preview-up'
--bind='ctrl-e:preview-down'
--bind='ctrl-u:preview-half-page-up'
--bind='ctrl-d:preview-half-page-down'
--bind='ctrl-b:preview-page-up'
--bind='ctrl-f:preview-page-down'
"
