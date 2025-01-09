#!/usr/bin/env bash

_git() {
	tput setaf 5
	local result=' '
	local bare
	bare=$(git rev-parse --is-bare-repository 2> /dev/null) || return # we're not in a repo
	if [ "$bare" = 'true' ]; then
		result+='bare'
	else
		local -r raw=$(git -C "$1" status --porcelain=v2 --show-stash --branch)

		# repo name
		local -r url="$(git remote get-url origin 2> /dev/null)"
		result+="$(basename -s .git "$url")/"

		# branch/commit
		local -r branch=$(echo "$raw" | grep -oP '(?<=^# branch.head ).*') && {
			if ! [ "$branch" = '(detached)' ]; then
				result+=$branch
			else
				result+=$(printf %.7s "$(echo "$raw" | grep -oP '(?<=^# branch.oid ).*')")
			fi
		}

		# status
		local status
		{
			# returns a string with unique XY status codes
			# '3 1' - staging, '4 1' - work tree, '3 2' - both
			chars() {
				# TODO awk stuff is gpt, check
				echo "$raw" | grep '^[12]' | awk -v pos="$1" -v num="$2" '{printf substr($0, pos, num)}' \
					| sed 's/[. #]//g' | fold -w1 | LC_ALL=C sort -u | tr -d '\n'
			}

			# XY codes from staging area (index)
			status+=$(chars 3 1)

			# dirty work tree
			[ -n "$(chars 4 1)" ] && status+='+'

			# untracked files
			echo "$raw" | grep -q '^?' && status+="?"
		}

		local desync
		[ -n "$url" ] && [ -n "$branch" ] && {
			# behind
			[ -n "$(git cherry "$branch" origin 2> /dev/null)" ] && desync+='<'
			# ahead
			[ -n "$(git cherry 2> /dev/null)" ] && desync+='>'
		}

		local -r stash=$(echo "$raw" | grep -qP '(?<=^# stash )\d+')

		printf %s "${status:+ $status}${desync:+ $desync}${stash:+ $stash}"
	fi
	tput sgr0
}

_code() {
	tput bold setaf 1
	local err=$__last_return_code
	[ "$err" -ne 0 ] && {
		printf ' %s\n' "ERR:$err"
	}
	tput sgr0
}

_jobs() {
	tput setaf 3
	((__n_jobs > 0)) && {
		printf %s " J:$__n_jobs"
	}
	tput sgr0
}

_time() {
	tput bold setaf 7
	printf %s " $(date +%H:%M)"
	tput sgr0
}

_ssh() {
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		printf ' %s\n' "ssh: $(whoami)@$(hostname)"
	fi
	tput sgr0
}

_path() {
	tput bold
	cwd=$(pwd)
	len=${#HOME}
	[[ $cwd == "$HOME"* ]] \
		&& cwd="~${cwd:len}"
	printf %s "$cwd"
	tput sgr0
}

_shlvl() {
	tput setaf 2
	[ -n "$SHLVL" ] && ((SHLVL > 1)) && printf %s " L$SHLVL"
	tput sgr0
}

_nix() {
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
PS1+='$(_code)'
PS1+='\n'
PS1+='$(_ssh)'
PS1+=' $(_path)$(_git)$(_shlvl)$(_nix)$(_time)$(_jobs)\n'
PS1+=' \$ '

PS2='│'
