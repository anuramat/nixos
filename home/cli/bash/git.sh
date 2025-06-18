#!/usr/bin/env bash

# TODO reconsider stderr/stdout depending on usecases
# TODO more local/readonly
# TODO total rehaul, then move

__free_repos_cand=("$HOME/notes" "/etc/nixos" "/var/www")
__free_repos=()
for i in "${__free_repos_cand[@]}"; do
	[ -d "$i" ] && __free_repos+=("$i")
done

ghooks() {
	# lists hooks in ghq repos
	find "$(ghq root)" -wholename '*/.git/hooks/*' -not -name '*.sample'
}

g() {
	# cd to ghq repo
	# $1? - prefill query
	# TODO rewrite with less assumptions, use ghq queries
	local -r root="$(ghq root)"
	local -r repo_relative_paths="$(fd . "$root" --exact-depth 3 | sed "s#${root}/##")"
	local chosen_path
	[ -n "$1" ] && {
		chosen_path=$(cd "$root" && echo "$repo_relative_paths" | fzf -f "$1" | head -n 1) || return
	} || chosen_path=$(cd "$root" && echo "$repo_relative_paths" | fzf) || return
	cd "$root/$chosen_path" || return
}

__gitgud_picker() {
	# pick a subset of a list with confirmation
	# stdin - NL separated list
	# $1? - prompt question (empty |-> auto-accept)
	# $2? - prefill query
	# stdout - NL separated list
	local repos
	repos="$(fzf -1 -q "$2")" || return 1
	echo "$repos"
	echo $'\t'"${repos//$'\n'/$'\n\t'}" >&2

	[ -z "$1" ] && return

	read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
	[ "$choice" = 'y' ]
}

grm() {
	# $1? - prefill query
	local selected
	selected=$(ghq list | __gitgud_picker "delete?" "$1") || return
	echo "$selected" | xargs -I{} bash -c 'yes | ghq rm {} 2>/dev/null'
}

gclone() {
	# $1? - repo name
	local -r before_dirs="$(ghq list -p | sort)"
	local repos=$1
	[ -z "$repos" ] && repos=$(gh repo list | cut -f 1)
	local selected
	selected="$(echo "$repos" | cut -f 1 | __gitgud_picker "")" || return
	echo "$selected" | xargs ghq get --no-recursive --parallel -p --silent || {
		echo "Couldn't clone"
		return 1
	}
	local -r after_dirs="$(ghq list -p | sort)"
	# show the cloned repos; a bit of a hack but whatever, seems to be working
	local -r new_dirs="$(comm -13 <(echo "$before_dirs") <(echo "$after_dirs"))"
	echo "$new_dirs" | xargs zoxide add
	gh repo set-default $(git config --get remote.origin.url | rev | cut -d "/" -f 1,2 | rev) 2> /dev/null || true
}

check() {
	__check nopull
}

down() {
	__check
}

__check() {
	# (pulls and) prints status of all repos
	case "$1" in
		"nopull" | "") ;;
		*)
			echo "illegal argument" >&2
			return 1
			;;
	esac
	local -r nopull="$1"

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
		status=$(__gitgud_git_prompt 1) && status=
		status="${pulled:+ [ff]}${status:+$(tput setaf 1)$status$(tput sgr0)}"
		[ -z "$status" ] && return
		echo "$name$status"
	}

	local dirty
	dirty=$(
		export -f get_dirty __gitgud_git_prompt
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

up() (
	# fast push+commit for personal repos
	# $1? - repo path
	cd "$1" || return 1

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
	prompt=$(__gitgud_git_prompt 1) || prompt="$(tput setaf 1)$prompt$(tput sgr0)"
	echo "status:$prompt"
)

gfork() {
	yes N | gh repo fork --default-branch-only "$1"
	gclone "$(basename $1)"
}

gcreate() {
	# creates and clones a repo with minimum amount of gh features turned on
	# $1 - name
	# $2? - visibility
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

	local -r git_root=$(git rev-parse --show-toplevel)
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
