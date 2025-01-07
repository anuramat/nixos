#!/usr/bin/env bash

_git_status() {
	local out=
	# porcelain escapes the path for us
	local raw=$(git -C "$1" status --porcelain=v2)

	# stash
	if stashed=$(echo "$raw" | head -n 1 | grep -oP '(?<=# stash )\d+'); then
		out+='$'
		raw=$(echo "$raw" | tail -n +2)
	fi

}

# TODO review the code
_git() {
	# bare repository case
	local bare
	bare=$(git rev-parse --is-bare-repository 2> /dev/null) || return
	tput setaf 2
	if [ "$bare" = 'true' ]; then
		printf 'bare'
	else
		local git_dir
		local git_dir="$(git rev-parse --git-dir 2> /dev/null | xargs realpath)"
		local -r root_dir="${git_dir/%"/.git"/}"
		printf ' '

		# Repository name
		local url
		local remote_exists=true
		url="$(git config --get remote.origin.url)" || remote_exists=false
		local -r repo_name="$(basename -s .git "${url:-$root_dir}")"
		printf %s "$repo_name"

		# Branch
		local branch="$(git branch --show-current)"
		[ -z "$branch" ] && branch="$(git -C "$root_dir" rev-parse --short HEAD)"
		printf %s "/$branch"

		# Status - first column from porcelain |> unique and sorted
		local git_status=$(git -C "$root_dir" status --porcelain -z \
			| grep -ozP -- '^\s*\K[A-Z]*' | tr -d '\0' | grep -o '.' | sort -u | tr -d '\n')
		# Check for unpushed commits
		[ "$remote_exists" = true ] && [ -n "$(git cherry)" ] && git_status+="^"
		# TODO git stash
		[ -n "$git_status" ] && printf %s ":$git_status"
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
