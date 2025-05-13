#!/usr/bin/env bash

# deps: _git_prompt defined in git_gud.sh

__git_user_ps1() {
	local -r prompt=$(_git_prompt)
	printf '%s' "${prompt:+ $(tput setaf 5)$prompt$(tput sgr0)}"
}

__code_user_ps1() {
	local -r err=$__last_return_code
	[ "$err" -ne 0 ] && printf ' %s\n' "$(tput bold setaf 1)ERR:$err"
	tput sgr0 # TODO for some reason if we put this into a printf arg, it eats the newline???
}

__jobs_user_ps1() {
	((__n_bg_jobs > 0)) && printf %s " $(tput setaf 3)J:$__n_bg_jobs$(tput sgr0)"
}

__time_user_ps1() {
	printf %s " $(tput bold setaf 7)$(date +%H:%M)$(tput sgr0)"
}

__ssh_user_ps1() {
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		printf ' %s\n' "$(whoami)@$(hostname)"
	fi
}

__path_user_ps1() {
	cwd=$(pwd)
	len=${#HOME}
	[[ $cwd == "$HOME"* ]] \
		&& cwd="~${cwd:len}"
	printf %s "$(tput bold)$cwd$(tput sgr0)"
}

__shlvl_user_ps1() {
	((SHLVL > 1)) && printf %s " $(tput setaf 2)L$SHLVL$(tput sgr0)"
}

__nix_user_ps1() {
	printf %s "${IN_NIX_SHELL:+ $(tput setaf 2)$IN_NIX_SHELL$(tput sgr0)}"
}

__set_vars() {
	__last_return_code=$?
	__n_bg_jobs=$(jobs | wc -l)
}
precmd_functions=(__set_vars "${precmd_functions[@]}")

PS1=''
PS1+='$(__code_user_ps1)'
PS1+='\n'
PS1+='$(__ssh_user_ps1)'
PS1+=' $(__path_user_ps1)$(__git_user_ps1)$(__shlvl_user_ps1)$(__nix_user_ps1)$(__time_user_ps1)$(__jobs_user_ps1)\n'
PS1+=' \$ '

PS2='│'
