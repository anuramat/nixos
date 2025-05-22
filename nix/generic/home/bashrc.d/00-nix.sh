#!/usr/bin/env bash

reflake() {
	if [ "$#" -ne 1 ]; then
		echo "Usage: ${FUNCNAME[0]} .../flake.lock"
		return 1
	fi

	local target_file="$1"
	local source_file="/etc/nixos/flake.lock"

	for file in "$source_file" "$target_file"; do
		[ -f "$file" ] || {
			echo "$file not found"
			return 1
		}
	done

	local new_value
	local replace_expr
	local prop
	jq --raw-output0 ".nodes | keys[]" "$target_file" | while IFS= read -r -d '' input_name; do
		# TODO check that .nodes.$input_name.original are equal, otherwise error out
		prop=".nodes.\"$input_name\".locked"
		new_value=$(jq -r "$prop | tojson" "$source_file")
		replace_expr="$prop = (\$arg | fromjson)"
		jq --arg arg "$new_value" "$replace_expr" "$target_file" | sponge "$target_file"
	done

	echo "synced $target_file with system flake.lock"
}
