#!/usr/bin/env bash

set -euo pipefail

paths=""
paths+=$(fd -e nix | grep 'default.nix$' | xargs -I{} dirname {})
paths+=$(fd -e nix | grep -v 'default.nix$' | grep -v '^flake.nix$')

while IFS= read -r path; do
	file=$(basename "$path")
	exp=$(printf './%s$' "$file")
	while IFS=: read -r matchfile matchstring; do
		printf 'file %s match %s' "$matchfile" "$matchstring"
	done < <(rg --no-config -g '*.nix' "$exp" --with-filename)
done < <(echo "$paths")
