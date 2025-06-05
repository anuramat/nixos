#!/usr/bin/env bash

set -euo pipefail

paths=""
paths+=$(fd -e nix | grep 'default.nix$' | xargs -I{} dirname {})
paths+=$(fd -e nix | grep -v 'default.nix$' | grep -v '^flake.nix$')

while IFS= read -r path; do
	file=$(basename "$path")
	while IFS=: read -r matchfile matchstring; do
		echo "$matchstring"
	done < <(rg --no-config -g '*.nix' "^\s*(\./.*$file)$" -r '${1}' --only-matching --with-filename /etc/nixos)
	break
done < <(echo "$paths")
