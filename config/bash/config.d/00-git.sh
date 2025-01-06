#!/usr/bin/env bash

__free_repos=("$HOME/notes" "/etc/nixos")

# cd to ghq repo
# optional: $1 - query; then you cd to the best match
# TODO rewrite with less assumptions, use ghq queries
g() {
	local -r root="$(ghq root)"
	local -r repo_relative_paths="$(fd . "$root" --exact-depth 3 | sed "s#${root}/##")"
	local chosen_path
	# cd $root so that fzf preview works properly
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
	repos="$(fzf)" || return 1
	echo "$repos"

	echo 'selected repositories:' >&2
	printf '%s' "\t$repos" | sed -z 's/\n/\n\t/g' >&2
	echo >&2

	read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
	[ "$choice" = 'y' ]
}

# rm ghq repo(s)
grm() {
	local repos
	repos=$(ghq list | __ghq_fzf_base "delete?") || return
	echo "$repos" | xargs -I{} bash -c 'yes | ghq rm {} 2>/dev/null'
}

# clone gh repo(s) with ghq
# optional $1 - owner
gclone() {
	local -r before_dirs="$(ghq list -p | sort)"
	local repos
	repos="$(gh repo list "$1" | cut -f 1 | __ghq_fzf_base "download?")" || return
	ghq get -P -p "${repos[@]}"
	local -r after_dirs="$(ghq list -p | sort)"
	local -r new_dirs="$(comm -13 <(echo "$before_dirs") <(echo "$after_dirs"))"
	zoxide add "${new_dirs[@]}"
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
	[ "$1" = all ] && {
		__gpush
		return
	}
	__heading="$(tput setaf 5 bold)%s$(tput sgr0)\n"
	for i in "${__free_repos[@]}"; do
		(
			# shellcheck disable=SC2059
			printf "$__heading" "*** pushing $(basename "$i") ***"
			cd "$i" || exit
			__gpush
		)
	done
}
