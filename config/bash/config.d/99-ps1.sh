#!/usr/bin/env bash

# depends on _git_prompt defined outside

__git() {
	tput setaf 5
	local -r prompt=$(_git_prompt)
	[ -n "$prompt" ] && printf ' %s' "$prompt"
	tput sgr0
}

__code() {
	tput bold setaf 1
	local err=$__last_return_code
	[ "$err" -ne 0 ] && {
		printf ' %s\n' "ERR:$err"
	}
	tput sgr0
}

__jobs() {
	tput setaf 3
	((__n_jobs > 0)) && {
		printf %s " J:$__n_jobs"
	}
	tput sgr0
}

__time() {
	tput bold setaf 7
	printf %s " $(date +%H:%M)"
	tput sgr0
}

__ssh() {
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		printf ' %s\n' "ssh: $(whoami)@$(hostname)"
	fi
	tput sgr0
}

__path() {
	tput bold
	cwd=$(pwd)
	len=${#HOME}
	[[ $cwd == "$HOME"* ]] \
		&& cwd="~${cwd:len}"
	printf %s "$cwd"
	tput sgr0
}

__shlvl() {
	tput setaf 2
	[ -n "$SHLVL" ] && ((SHLVL > 1)) && printf %s " L$SHLVL"
	tput sgr0
}

__nix() {
	tput setaf 2
	[ -n "$IN_NIX_SHELL" ] && printf %s " $IN_NIX_SHELL"
	tput sgr0
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
