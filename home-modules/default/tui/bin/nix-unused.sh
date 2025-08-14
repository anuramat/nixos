#!/usr/bin/env bash

set -euo pipefail

while IFS= read -r path; do
	filename=$(basename "$path")
	exp="(\./.*$filename)"
	rg_args=(--no-config -g '*.nix' -r '${1}' --only-matching --with-filename)

	used=false
	while IFS=: read -r matchfile matchstring; do
		normalized=$(realpath -q "$(dirname "$matchfile")/$matchstring") || continue
		if [ "$path" = "$normalized" ]; then
			used=true && break
		fi
	done < <(
		rg "${rg_args[@]}" "^\s*$exp$" /etc/nixos || true
		rg "${rg_args[@]}" "import $exp" /etc/nixos || true
	)
	[[ $used == false ]] && echo "$path"
done < <(
	# folder imports
	fd -ae nix | grep '/default\.nix$' | xargs -I{} dirname {}
	# file imports
	fd -ae nix | rg --no-config -v '(/flake\.nix$|/default\.nix)'
)
