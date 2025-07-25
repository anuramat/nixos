#!/usr/bin/env bash

set -euo pipefail

onlyfails=t

red() {
	printf '\033[38;2;255;0;0m%s\033[0m\n' "$1"
}

while IFS= read -r path; do
	echo "$path" | rg --no-config -vq 'hosts/[^/]+$' || continue
	filename=$(basename "$path")
	use_counter=0
	exp="(\./.*$filename)"
	rg_args=(--no-config -g '*.nix' -r '${1}' --only-matching --with-filename)
	while IFS=: read -r matchfile matchstring; do
		normalized=$(realpath -q "$(dirname "$matchfile")/$matchstring") || continue
		if [ "$path" = "$normalized" ]; then
			((use_counter++)) || true
			[ -n "$onlyfails" ] && break
		fi
	done < <(
		rg "${rg_args[@]}" "^\s*$exp$" /etc/nixos || true
		rg "${rg_args[@]}" "import $exp" /etc/nixos || true
	)
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
done < <(
	fd -ae nix | grep '/default\.nix$' | xargs -I{} dirname {}
	fd -ae nix | rg --no-config -v '(/flake\.nix$|/default\.nix)'
)
