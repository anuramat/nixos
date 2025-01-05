#!/usr/bin/env bash

# Goes through "git status --porcelain=v1" output, searching for the letter
__git_status_attr() {
	# $1 - target letter
	# $2 - output symbol (defautls to $1)
	grep -q -e "^.$1" -e "^$1." && {
		[ -n "$2" ] && printf '%s' "$2" && return
		printf '%s' "$1"
	}
}

# Returns git status string of the form '[A-Z]+'
__git_status() {
	# $1 - root dir
	local porcelain=$(git -C "$1" status --porcelain)
	printf '%s' "ACDMRTUX" | while read -rn1 char; do
		printf '%s' "$(echo "$porcelain" | __git_status_attr "$char")"
	done
}

__git_prompt() {
	tput setaf 2
	local git_dir
	if git_dir="$(git rev-parse --git-dir 2> /dev/null)"; then
		git_dir="$(realpath "$git_dir")"
		local -r root_dir="${git_dir/%"/.git"/}"
		local -r sep=':'

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
		printf %s "$sep$branch"

		# Status
		local git_status="$(__git_status "$root_dir")"
		[ -z "$(git cherry)" ] && git_status+="^"
		[ -n "$git_status" ] && printf %s "$sep$git_status"
	fi
	tput sgr0
}

# Set up colors
__bold=$(tput bold)
__norm=$(tput sgr0)
__col0=$(tput setaf 0)
__col1=$(tput setaf 1)
__col2=$(tput setaf 2)

__return_code_prompt() {
	local err=$__last_return_code
	[ "$err" -ne 0 ] && {
		# command -v errno &> /dev/null && err=$(errno "$err")
		tput bold setaf 1
		echo "$err"
		tput sgr0
	}
}

__path="$(tput bold)\w$(tput sgr0)"

# Capture last return code
PROMPT_COMMAND='__last_return_code=$?'"${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
PS1=$(printf '%s' '$(__return_code_prompt)' '' "$__path \$(__git_prompt)" $'\n $ ')
PS2='│'
