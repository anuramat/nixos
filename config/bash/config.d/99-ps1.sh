#!/usr/bin/env bash

# TODO review the code
_git() {
	local bare
	bare=$(git rev-parse --is-bare-repository 2> /dev/null) || return # we're not in a repo
	tput setaf 2
	printf ' '
	if [ "$bare" = 'true' ]; then
		printf 'bare'
	else
		# repo name
		local -r url="$(git remote get-url origin 2> /dev/null)"
		printf %s "$(basename -s .git "$url")/"

		# porcelain escapes the paths for us
		local raw=$(git -C "$1" status --porcelain=v2 --show-stash --branch)

		# branch/commit
		local -r branch=$(echo "$raw" | grep -oP '(?<=^# branch.head ).*') && {
			if ! [ "$branch" = '(detached)' ]; then
				printf %s "$branch"
			else
				printf %.6s "$(echo "$raw" | grep -oP '(?<=^# branch.oid ).*')"
			fi
		}

		local status

		# stash
		echo "$raw" | grep -qP '(?<=^# stash )\d+' && status+='$'

		# check for unpushed commits
		[ -n "$url" ] && [ -n "$(git cherry)" ] && status+='^'

		# print markers
		[ -n "$git_status" ] && printf %s ":$git_status"

		# TODO rewrite this in porcelain v2
		# status - first column from porcelain |> unique and sorted
		local git_status=$(git -C "$root_dir" status --porcelain -z \
			| grep -ozP -- '^\s*\K[A-Z]*' | tr -d '\0' | grep -o '.' | sort -u | tr -d '\n')
	fi
	tput sgr0
}

_code() {
	local err=$__last_return_code
	[ "$err" -ne 0 ] && {
		tput bold setaf 1
		printf '%s\n' " ERR:$err"
		tput sgr0
	}
}

_jobs() {
	# TODO figure out how to hide zoxide (?) job
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
		printf '%s\n' " $(whoami)@$(hostname)"
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
