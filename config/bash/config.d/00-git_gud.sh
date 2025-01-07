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

# pick a ghq repo
# stdin - \n separated list of repos
# $1 - prompt question
# stdout - \n separated list of repos
__ghq_fzf_base() {
	local repos
	repos="$(fzf --bind one:accept)" || return 1
	echo "$repos"

	echo 'selected repositories:' >&2
	printf '%s' "$repos" | sed 's/^/\t/' >&2
	echo >&2

	read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
	[ "$choice" = 'y' ]
}

# rm ghq repo(s)
# optional $1 - repo
grm() {
	local repos=$1
	[ -z "$repos" ] && repos=$(ghq list)
	local selected
	selected=$(echo "$repos" | __ghq_fzf_base "delete?") || return
	echo "$selected" | xargs -I{} bash -c 'yes | ghq rm {} 2>/dev/null'
}

# clone your gh repo(s) with ghq
# optional $1 - repo (as interpreted by ghq)
gclone() {
	local -r before_dirs="$(ghq list -p | sort)"
	local repos=$1
	[ -z "$repos" ] && repos=$(gh repo list)
	local selected
	selected="$(echo "$repos" | cut -f 1 | __ghq_fzf_base "download?")" || return
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

# check if ghq/personal repos are pushed
gcheck() {
	local root=$(ghq root)
	local dirty
	get_dirty() {
		local prefix_length="$1"
		while IFS= read -r -d '' path; do
			(
				cd "$path" || return
				[ -z "$(git status --porcelain)" ] && [ -z "$(git cherry)" ] && return
				[ -n "$prefix_length" ] && printf '\t%s\n' "${path:prefix_length}" && return
				printf '\t%s\n' "$(basename "$path")"
			)
		done
	}
	dirty=$(
		printf '%s\0' "${__free_repos[@]}" | get_dirty
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
	[ "${1:-this}" != "all" ] && {
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
