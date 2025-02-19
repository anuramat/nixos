#!/usr/bin/env bash

# depends on _git_prompt defined outside

__git() {
	local -r prompt=$(_git_prompt)
	printf '%s' "${prompt:+ $(tput setaf 5)$prompt$(tput sgr0)}"
}

__code() {
	local -r err=$__last_return_code
	[ "$err" -ne 0 ] && printf ' %s\n' "$(tput bold setaf 1)ERR:$err"
	tput sgr0 # TODO for some reason if we put this into a printf arg, it eats the newline???
}

__jobs() {
	((__n_jobs > 0)) && printf %s " $(tput setaf 3)J:$__n_jobs$(tput sgr0)"
}

__time() {
	printf %s " $(tput bold setaf 7)$(date +%H:%M)$(tput sgr0)"
}

__ssh() {
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		printf ' %s\n' "ssh: $(whoami)@$(hostname)"
	fi
}

__path() {
	cwd=$(pwd)
	len=${#HOME}
	[[ $cwd == "$HOME"* ]] \
		&& cwd="~${cwd:len}"
	printf %s "$(tput bold)$cwd$(tput sgr0)"
}

__shlvl() {
	((SHLVL > 1)) && printf %s " $(tput setaf 2)L$SHLVL$(tput sgr0)"
}

__nix() {
	printf %s "${IN_NIX_SHELL:+ $(tput setaf 2)$IN_NIX_SHELL$(tput sgr0)}"
}

__set_vars() {
	__last_return_code=$?
	__n_jobs=$(jobs | wc -l)
}
precmd_functions=(__set_vars "${precmd_functions[@]}")

PS1=''
PS1+='$(__code)'
PS1+='\n'
PS1+='$(__ssh)'
PS1+=' $(__path)$(__git)$(__shlvl)$(__nix)$(__time)$(__jobs)\n'
PS1+=' \$ '

PS2='│'
