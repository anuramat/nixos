#!/usr/bin/env bash

set -euo pipefail

paths=""
paths+=$(fd -ae nix | grep 'default.nix$' | xargs -I{} dirname {})
paths+=$'\n'
paths+=$(fd -ae nix | grep -v 'default.nix$' | grep -v '^flake.nix$')

onlyfails=t

red() {
	printf '\033[38;2;255;0;0m%s\033[0m\n' "$1"
}

while IFS= read -r path; do
	filename=$(basename "$path")
	use_counter=0
	while IFS=: read -r matchfile matchstring; do
		if [ "$path" = "$(realpath "$(dirname "$matchfile")/$matchstring")" ]; then
			((use_counter++)) && true
			[ -n "$onlyfails" ] && break
		fi
	done < <(rg --no-config -g '*.nix' "^\s*(\./.*$filename)$" -r '${1}' --only-matching --with-filename /etc/nixos)
	if ((use_counter > 0)); then
		[ -z "$onlyfails" ] && {
			echo "$path: $use_counter references"
		}
	else
		if [ -z "$onlyfails" ]; then
			red "$path: not found"
		else
			echo "$path"
		fi
	fi
done < <(echo "$paths")
