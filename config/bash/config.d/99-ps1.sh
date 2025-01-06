#!/usr/bin/env bash

# TODO review the code
_git() {
	tput setaf 2
	local git_dir
	if git_dir="$(git rev-parse --git-dir 2> /dev/null)"; then
		git_dir="$(realpath "$git_dir")"
		local -r root_dir="${git_dir/%"/.git"/}"
		printf ' '

		# Bare repository case
		if [ "$(git rev-parse --is-bare-repository 2> /dev/null)" = "true" ]; then
			printf %s "$(basename -s .git "$git_dir")"
			return
		fi

		# Repository name
		local -r url="$(git config --get remote.origin.url)"
		local -r repo_name="$(basename -s .git "${url:-$root_dir}")"
		printf %s "$repo_name"

		# Branch
		local branch="$(git branch --show-current)"
		[ -z "$branch" ] && branch="$(git -C "$root_dir" rev-parse --short HEAD)"
		printf %s "/$branch"

		# Status
		local git_status=$(git -C "$root_dir" status --porcelain -z \
			| grep -ozP -- '^\s*\K[A-Z]*' | tr -d '\0' | grep -o '.' | sort -u | tr -d '\n')
		# first column from porcelain |> unique and sorted
		[ -n "$(git cherry)" ] && git_status+="^"
		[ -n "$git_status" ] && printf %s ":$git_status"
	fi
	tput sgr0
}

_code() {
	local err=$__last_return_code
	[ "$err" -ne 0 ] && {
		tput bold setaf 1
		printf %s " ERR:$err\n"
		tput sgr0
	}
}

_jobs() {
	n_jobs=$(jobs | wc -l)
	((n_jobs > 0)) && {
		tput bold setaf 3
		printf %s " J:$n_jobs"
		tput sgr0
	}
}

_time() {
	printf %s " $(date +%H:%M)"
}

_ssh() {
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		printf '%s' " $(whoami)@$(hostname)\n"
	fi
}

_path() {
	cwd=$(pwd)
	len=${#HOME}
	[[ $cwd == "$HOME"* ]] \
		&& cwd="~${cwd:len}"
	tput bold
	printf %s "$cwd"
	tput sgr0
}

_shlvl() {
	[ -n "$SHLVL" ] && ((SHLVL > 1)) && printf %s " L:$SHLVL"
}

_nix() {
	[ -n "$IN_NIX_SHELL" ] && printf %s " $IN_NIX_SHELL"
}

PROMPT_COMMAND='__last_return_code=$?'"${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"

PS1=
PS1+=' $(_code)'
PS1+='\n'
PS1+=' $(_ssh)'
PS1+='$(_path)$(_git)$(_jobs)$(_shlvl)$(_nix)$(_time)\n'
PS1+=' \$ '

PS2='│'
