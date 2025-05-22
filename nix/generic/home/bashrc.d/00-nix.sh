#!/usr/bin/env bash

reflake() {
	if [ "$#" -ne 1 ]; then
		echo "Usage: ${FUNCNAME[0]} .../flake.lock"
		return 1
	fi

	local target="$1"
	local source="/etc/nixos/flake.lock"

	for file in "$source" "$target"; do
		[ -f "$file" ] || {
			echo "$file not found"
			return 1
		}
	done

	local locked
	local replace_locked_expr
	jq --raw-output0 ".nodes | keys[]" "$target" | while IFS= read -r -d '' input; do
		# TODO skip keys from input that are not in target
		# TODO check that .nodes.input.original are equal, otherwise skip
		locked=$(jq -r ".nodes.\"$input\".locked | tojson" "$source")
		replace_locked_expr=".nodes.\"$input\".locked = (\$input | fromjson)"
		jq --arg input "$locked" "$replace_locked_expr" "$target" | sponge "$target"
	done

	echo "synced $target with system flake.lock"
}
