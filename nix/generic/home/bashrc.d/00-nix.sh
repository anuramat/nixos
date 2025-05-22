#!/usr/bin/env bash

reflake() {
	if [ "$#" -ne 1 ]; then
		echo "Usage: ${FUNCNAME[0]} .../flake.lock"
		exit 1
	fi

	local target="$1"
	local source="/etc/nixos/flake.lock"

	for i in "$source" "$target"; do
		[ -f "$i" ] || {
			echo "$i not found"
			return 1
		}
	done

	# Create a temporary file
	TMP_FILE=$(mktemp)

	# Use jq to update the flake-utils entry

	local fields=("flake-utils" "nixpkgs-unstable")
	for i in "${fields[@]}"; do
		# TODO add "original" check
		jq --arg input "$(jq -r ".nodes.\"$i\".locked | tojson" "$source")" ".nodes.\"$i\".locked = (\$input | fromjson)" "$target" | sponge "$target"
	done

	echo "synced $target with system flake.lock"
}
