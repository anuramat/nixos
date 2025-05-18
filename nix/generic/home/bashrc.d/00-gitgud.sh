#!/usr/bin/env bash

# TODO unsafe path handling
# TODO reconsider stderr/stdout depending on usecases
# more locals

__free_repos_cand=("$HOME/notes" "/etc/nixos" "/var/www")
__free_repos=()
for i in "${__free_repos_cand[@]}"; do
	[ -d "$i" ] && __free_repos+=("$i")
done

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
__gitgud_picker() {
	local repos
	repos="$(fzf -1 -q "$2")" || return 1
	echo "$repos"
	echo $'\t'"${repos//$'\n'/$'\n\t'}" >&2
	read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
	[ "$choice" = 'y' ]
}

# rm ghq repo(s)
# $1 - repo (optional)
git_rm() {
	local selected
	selected=$(ghq list | __gitgud_picker "delete?" "$1") || return
	echo "$selected" | xargs -I{} bash -c 'yes | ghq rm {} 2>/dev/null'
}

# `ghq get` with extras:
# * on empty args, shows `gh` repos in fzf
# * default remote in `gh`, so that 'github_sync' does the expected thing
# * adds the path to zoxide
# $1 - repo as interpreted by ghq, optional
git_clone() {
	local -r before_dirs="$(ghq list -p | sort)"
	local repos=$1
	[ -z "$repos" ] && repos=$(gh repo list | cut -f 1)
	local selected
	selected="$(echo "$repos" | cut -f 1 | __gitgud_picker "download?")" || return
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
github_sync() {
	gh repo sync "$(gh repo set-default --view)" # TODO is the argument still required?
	git pull
}

check() {
	down check
}

# pull and show status of all repos
down() {
	local -r nopull="$1"
	case "$nopull" in
		"check" | "") ;;
		*)
			echo "illegal argument; allowed: 'check' | ''" >&2
			return 1
			;;
	esac

	# repos are taken from ghq and hardcoded array
	local -r root=$(ghq root)

	# shellcheck disable=SC2317
	get_dirty() {
		local -r nopull="$1"
		local -r prefix_length="$2"
		local -r path="$3"
		cd "$path" || return

		local -r name="${path:prefix_length}"

		[ -z "$nopull" ] && {
			local before=$(git rev-parse @)
			git pull --ff-only &> /dev/null
			[ "$before" != "$(git rev-parse @)" ] && local pulled=1
		}

		local status
		status=$(_git_prompt 1) && status=
		status="${pulled:+ [ff]}${status:+$(tput setaf 1)$status$(tput sgr0)}"
		[ -z "$status" ] && return
		echo "$name$status"
	}

	local dirty
	dirty=$(
		export -f get_dirty _git_prompt
		printf '%s\0' "${__free_repos[@]}" | xargs -0 -P 0 -I {} bash -c "get_dirty '$nopull' 0 {}" | LC_ALL=C sort
		ghq list -p | xargs -P 0 -I {} bash -c "get_dirty '$nopull' $((${#root} + 1)) {}" | LC_ALL=C sort
	)
	[ -z "$dirty" ] && {
		echo "all clean!" >&2
		return
	}
	echo "$dirty" >&2
	return 1
}

# fast push+commit for personal repos
up() (
	cd "$1" || exit 1
	local ok
	# check that we're in a personal repo directory
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

	git add -A

	printf %s 'committing: '
	if git diff-index --quiet HEAD; then
		echo "nothing to commit"
	else
		git commit -qam "auto: $(hostname)" || return
		echo "ok"
	fi

	printf %s 'pulling: '
	local -r pull_before=$(git rev-parse "@{u}")
	git pull --ff --no-edit -q || return
	if [ "$pull_before" == "$(git rev-parse "@{u}")" ]; then
		echo "local is already up to date"
	else
		echo "updated local"
	fi

	printf %s 'pushing: '
	local -r push_before=$(git rev-parse "@{push}")
	git push -q || return
	if [ "$push_before" == "$(git rev-parse "@{push}")" ]; then
		echo "remote is already up to date"
	else
		echo "updated remote"
	fi

	local prompt
	prompt=$(_git_prompt 1) || prompt="$(tput setaf 1)$prompt$(tput sgr0)"
	echo "status:$prompt"
)

github_create() {
	name=$1
	visibility=private
	[ -n "$2" ] && visibility=$2

	path=$(ghq create "$name") || {
		echo "couldn't create the repo" >&2
		return 1
	}
	cd "$path" || {
		echo "couldn't cd" >&2
		return 1
	}
	git commit --allow-empty -m "init"
	gh repo create "--$visibility" --disable-issues --disable-wiki --push --source "$path"
	gh repo set-default
	gh repo edit --enable-projects=false
}

__gitgud_git_prompt() {
	local -r only_state=$1 # don't show branch/commit

	local bare
	bare=$(git rev-parse --is-bare-repository 2> /dev/null) || return # we're not in a repo
	if [ "$bare" = 'true' ]; then
		printf 'bare'
		return
	fi

	local -r git_root=$(dirname "$(realpath "$(git rev-parse --git-dir)")")
	(
		cd "$git_root" || exit
		local -r raw=$(git status --porcelain=v2 --show-stash --branch)

		# branch/commit
		local branch=$(echo "$raw" | grep -oP '(?<=^# branch.head ).*')
		local commit
		if [ "$branch" = '(detached)' ]; then
			branch=''
			commit=$(printf %.7s "$(echo "$raw" | grep -oP '(?<=^# branch.oid ).*')")
		fi

		# status
		local status
		{
			# returns a string with unique XY status codes
			# '3 1' - staging, '4 1' - work tree, '3 2' - both
			chars() {
				# TODO awk stuff is gpt, check
				echo "$raw" | grep '^[12u]' | awk -v pos="$1" -v num="$2" '{printf substr($0, pos, num)}' \
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
		# behind
		[ -n "$(git cherry @ "@{push}" 2> /dev/null)" ] && desync+='<'
		# ahead
		[ -n "$(git cherry "@{u}" @ 2> /dev/null)" ] && desync+='>'
		# TODO add unpushed commits from other branches with a special flag?

		local -r stash=$(echo "$raw" | grep -oP '(?<=^# stash )\d+')

		local -r state=$(printf %s "${status:+ $status}${desync:+ $desync}${stash:+ \$$stash}")

		if [ -z "$only_state" ]; then
			# for PS1: prepend branch/hash
			printf %s "${branch:-$commit}$state"
		else
			printf %s "${state:- clean}"
		fi

		# error on dirty
		[ -z "$state" ]
	)
}
