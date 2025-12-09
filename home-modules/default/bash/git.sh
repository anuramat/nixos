#!/usr/bin/env bash

# TODO reconsider stderr/stdout depending on usecases
# TODO more local/readonly
# TODO total rehaul, then move

__free_repos_cand=("$HOME/notes" "/etc/nixos" "/var/www")
__free_repos=()
for i in "${__free_repos_cand[@]}"; do
	[ -d "$i" ] && __free_repos+=("$i")
done

# XXX checked ok
ghooks() {
	# lists hooks in ghq repos
	find "$(ghq root)" -wholename '*/.git/hooks/*' -not -name '*.sample'
}

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

	[ "$1" = "" ] && return

	read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
	[ "$choice" = 'y' ]
}

# XXX checked, ok
grm() {
	# $1? - prefill query
	local selected
	selected=$(ghq list | __gitgud_picker "delete?" "$1") || return
	xargs -I{} bash -c 'yes | ghq rm {} 2>/dev/null' <<<"$selected"
}

# XXX checked ok
__cd_gh_owner() {
	local -r path="$(ghq root)/github.com/$1"
	mkdir -p "$path" || return 1
	cd "$path" || return 1
}

# XXX checked ok
gclone() {
	# $1? - a single repo name
	local repos=$1

	# no repo name? open picker
	[ "$repos" = "" ] && {
		repos=$(gh repo list | cut -f 1 | __gitgud_picker "") || {
			echo "Selection cancelled"
			return
		}
	}

	for repo in "${repos[@]}"; do
		local owner
		owner=$(gh repo view "$repo" --json owner --jq '.owner.login') || return 1
		__cd_gh_owner "$owner" || return 1
		gh repo clone "$repo"
	done
	cd "$(basename "${repo%/}")" || return 1 # return to stfu the linter
}

# XXX checked, ok
__zoxide_add_ghq() {
	# add all ghq repos to zoxide
	find "$(ghq root)" -maxdepth 3 -mindepth 3 -print0 | xargs -0 zoxide add
}

check() {
	__check nopull
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

	# shellcheck disable=SC2329
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

# XXX checked ok
gfork() {
	local -r repo="$1"
	local auth_output
	auth_output=$(gh auth status --active) || return 1
	local user
	user=$(grep -oP 'account \K\S+' <<<"$auth_output")
	__cd_gh_owner "$user" || return 1
	gh repo fork "$repo" --default-branch-only --clone
	cd "$(basename "${repo%/}")" || return 1 # return to stfu the linter
}

# XXX checked ok
gcreate() {
	# creates and clones a repo with minimum amount of gh features turned on
	# $1 - name
	# $2? - public|private
	name=$1
	visibility=private
	[ "$2" != "" ] && visibility=$2
	case "$2" in
		private | public) ;;
		*) return 1 ;;
	esac

	path=$(ghq create "$name") || return 1
	cd "$path" || return 1
	git commit --allow-empty -m "init"
	gh repo create "--$visibility" --disable-issues --disable-wiki --push --source "$path"
	gh repo set-default
	gh repo edit --enable-projects=false
}

__gitgud_git_prompt() {
	status=$(starship module git_status)
	printf %s "$status"

	# dirty => non-zero return code:
	printf %s "$status" | ansifilter | grep -qv '\S'
}
