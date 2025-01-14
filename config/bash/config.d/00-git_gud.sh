#!/usr/bin/env bash

# TODO unsafe path handling

__free_repos=("$HOME/notes" "/etc/nixos")

# cd to ghq repo
# optional: $1 - query (best match is picked)
# TODO rewrite with less assumptions, use ghq queries
g() {
	local -r root="$(ghq root)"
	local -r repo_relative_paths="$(fd . "$root" --exact-depth 3 | sed "s#${root}/##")"
	local chosen_path
	[ -n "$1" ] && {
		chosen_path=$(cd "$root" && echo "$repo_relative_paths" | fzf -f "$1" | head -n 1) || return
	} || chosen_path=$(cd "$root" && echo "$repo_relative_paths" | fzf) || return
	cd "$root/$chosen_path" || return
}

# pick a subset of a list with confirmation
# stdin - \n separated list of repos
# $1 - prompt question
# $2 - query (optional)
# stdout - \n separated list of repos
__picker() {
	local repos
	repos="$(fzf -1 -q "$2")" || return 1
	echo "$repos"
	echo $'\t'"${repos//$'\n'/$'\n\t'}" >&2
	read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
	[ "$choice" = 'y' ]
}

# rm ghq repo(s)
# $1 - repo (optional)
grm() {
	local selected
	selected=$(ghq list | __picker "delete?" "$1") || return
	echo "$selected" | xargs -I{} bash -c 'yes | ghq rm {} 2>/dev/null'
}

# clone repo(s) with ghq
# $1 - repo as interpreted by ghq, optional
gclone() {
	local -r before_dirs="$(ghq list -p | sort)"
	local repos=$1
	[ -z "$repos" ] && repos=$(gh repo list | cut -f 1)
	local selected
	selected="$(echo "$repos" | cut -f 1 | __picker "download?")" || return
	echo "$selected" | xargs ghq get --no-recursive --parallel -p --silent || {
		echo "Couldn't clone"
		return 1
	}
	local -r after_dirs="$(ghq list -p | sort)"
	# HACK
	local -r new_dirs="$(comm -13 <(echo "$before_dirs") <(echo "$after_dirs"))"
	echo "$new_dirs" | xargs zoxide add
	# HACK with remote url
	echo "$new_dirs" | xargs -I{} bash -c 'cd {}; gh repo set-default $(git config --get remote.origin.url | rev | cut -d "/" -f 1,2 | rev)'
}

# sync a fork with the upstream
gsync() {
	gh repo sync "$(gh repo set-default --view)"
	git pull
}

# fetch and show status of all repos
gcheck() {
	# repos are taken from ghq and hardcoded array
	local root=$(ghq root)
	local dirty
	get_dirty() {
		local prefix_length="$1"
		while IFS= read -r -d '' path; do
			(
				cd "$path" || return
				prompt=$(_git_prompt hide_clean)
				[ -z "$prompt" ] && return
				prompt="$(tput setaf 1)$prompt$(tput sgr0)"
				printf '\t%s\n' "${path:prefix_length} $prompt" && return
			)
		done
	}
	dirty=$(
		printf '%s\0' "${__free_repos[@]}" | get_dirty 0
		ghq list -p | tr '\n' '\0' | get_dirty ${#root}
	)
	[ -z "$dirty" ] && {
		echo "all clean!"
		return
	}
	echo "dirty repos:"
	printf "%s\n" "$dirty"
}

# push+commit on personal repos
__gpush() {
	local ok
	for i in "${__free_repos[@]}"; do
		[[ "$(realpath .)" == "$i"* ]] && {
			ok=1
			break
		}
	done
	[ -z "$ok" ] && {
		echo "illegal directory"
		return 1
	}
	git add .
	git commit -am "auto: $(hostname)"
	git pull --ff --no-edit
	git push
}

# push all personal repos
gpush() {
	case "$1" in
		.)
			__gpush
			return
			;;
		*) ;;
	esac

	[ "${1:-all}" != "all" ] && {
		__gpush
		return
	}
	__heading="$(tput setaf 5 bold)%s$(tput sgr0)\n"
	# shellcheck disable=SC2317
	wrapper() {
		# shellcheck disable=SC2059
		printf "$__heading" "*** pushing $(basename "$1") ***"
		cd "$1" || exit
		__gpush
	}
	cmd="subcat"
	for path in "${__free_repos[@]}"; do
		cmd+=$(printf ' <(wrapper "%s" 2>&1)' "$path")
	done
	eval "$cmd"
}

gcreate() {
	name=$1
	visibility=private
	[ -n "$2" ] && visibility=$2

	path=$(ghq create "$name") || {
		echo "Couldn't create the repo"
		return 1
	}
	cd "$path" || {
		echo "Couldn't cd"
		return 1
	}
	git commit --allow-empty -m "init"
	gh repo create "--$visibility" --disable-issues --disable-wiki --push --source "$path"
	gh repo set-default
	gh repo edit --enable-projects=false
}

_git_prompt() {
	local -r hide_clean=$1
	[ -n "$hide_clean" ] && [ "$hide_clean" != "hide_clean" ] && {
		echo "Wrong argument to git prompt" >&2
		return 1
	}

	local bare
	bare=$(git rev-parse --is-bare-repository 2> /dev/null) || return # we're not in a repo
	local result
	if [ "$bare" = 'true' ]; then
		result+='bare'
	else
		local -r raw=$(git status --porcelain=v2 --show-stash --branch)

		# branch/commit
		local branch=$(echo "$raw" | grep -oP '(?<=^# branch.head ).*')
		if [ "$branch" = '(detached)' ]; then
			branch=''
			local commit=$(printf %.7s "$(echo "$raw" | grep -oP '(?<=^# branch.oid ).*')")
		fi

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

		local -r stash=$(echo "$raw" | grep -oP '(?<=^# stash )\d+')

		result=$(printf %s "${branch:-$commit}${status:+ $status}${desync:+ $desync}${stash:+ \$$stash}")
		[ -n "$hide_clean" ] && [ "$result" = "$branch" ] && return
		printf %s "$result"
	fi
}
