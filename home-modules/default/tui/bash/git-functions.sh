#!/usr/bin/env bash

# Shell context functions that can't be standalone scripts

__free_repos_cand=("$HOME/notes" "/etc/nixos" "/var/www")
__free_repos=()
for i in "${__free_repos_cand[@]}"; do
	[ -d "$i" ] && __free_repos+=("$i")
done

# XXX checked ok
g() {
	# cd to ghq repo
	# $1? - query (zoxide style)
	local -r root="$(ghq root)"
	local -r repo_relative_paths="$(find "$root" -mindepth 3 -maxdepth 3 | sed "s#$root/\?##")"
	local path
	local args=()
	[ "$1" != "" ] && args=(-f "$1")
	path=$(fzf "${args[@]}" <<<"$repo_relative_paths") || return
	cd "$root/$(head -n 1 <<<"$path")" || return
}

__gitgud_git_prompt() {
	status=$(starship module git_status)
	printf %s "$status"

	# dirty => non-zero return code:
	printf %s "$status" | ansifilter | grep -qv '\S'
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
	local -r root="$(ghq root)"

	# shellcheck disable=SC2317
	get_dirty() {
		local -r nopull="$1"
		local -r prefix_length="$2"
		local -r path="$3"
		cd "$path" || return

		local -r name="${path:prefix_length}"

		[ "$nopull" = "" ] && {
			local before
			before=$(git rev-parse @)
			git pull --ff-only &>/dev/null
			[ "$before" != "$(git rev-parse @)" ] && local pulled=1
		}

		local status
		status=$(__gitgud_git_prompt) && status=
		status="${pulled:+ [ff]}${status:+$(tput setaf 1)$status$(tput sgr0)}"
		[ "$status" = "" ] && return
		echo "$name$status"
	}

	local dirty
	dirty=$(
		export -f get_dirty __gitgud_git_prompt
		printf '%s\0' "${__free_repos[@]}" | xargs -0 -P 0 -I {} bash -c "get_dirty '$nopull' 0 {}" | LC_ALL=C sort
		ghq list -p | xargs -P 0 -I {} bash -c "get_dirty '$nopull' $((${#root} + 1)) {}" | LC_ALL=C sort
	)
	[ "$dirty" = "" ] && {
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
	[ "$ok" = "" ] && {
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
	local -r pull_before="$(git rev-parse "@{u}")"
	git pull --ff --no-edit -q || return
	if [ "$pull_before" == "$(git rev-parse "@{u}")" ]; then
		echo "local is already up to date"
	else
		echo "updated local"
	fi

	printf %s 'pushing: '
	local -r push_before="$(git rev-parse "@{push}")"
	git push -q || return
	if [ "$push_before" == "$(git rev-parse "@{push}")" ]; then
		echo "remote is already up to date"
	else
		echo "updated remote"
	fi

	local prompt
	prompt=$(__gitgud_git_prompt) || prompt="$(tput setaf 1)$prompt$(tput sgr0)"
	echo "status:$prompt"
)