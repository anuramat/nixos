#!/usr/bin/env bash

# TODO code review
__git_prompt() {
	tput setaf 2
	local git_dir
	if git_dir="$(git rev-parse --git-dir 2> /dev/null)"; then
		git_dir="$(realpath "$git_dir")"
		local -r root_dir="${git_dir/%"/.git"/}"

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

__return_code_prompt() {
	local err=$__last_return_code
	[ "$err" -ne 0 ] && {
		tput bold setaf 1
		echo " $err"
		tput sgr0
	}
}

# TODO maybe work on shortening depending on terminal width
__path="\n $(tput bold)\w$(tput sgr0)"

PROMPT_COMMAND='__last_return_code=$?'"${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
PS1=$(printf '%s' '$(__return_code_prompt)' "$__path" ' $(__git_prompt)')
PS1+='\n $ '
PS2='│'
