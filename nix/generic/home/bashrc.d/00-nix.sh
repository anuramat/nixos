#!/usr/bin/env bash

__jq_equals() {
	if [ "$#" -ne 3 ]; then
		echo 'error(usage): __jq_equals: not enough args'
		return 1
	fi
	local prop=$1
	local a=$2
	local b=$3

	local prop_a=$(jq -r "$prop | tojson" "$a")
	local match=$(jq -r --arg prop_a "$prop_a" "$prop == (\$prop_a | fromjson)" "$b")
	[ "$match" == true ]
}

reflake() {
	local target_file="$1"
	[ -z "$target_file" ] && target_file=./flake.lock
	[ -f "$target_file" ] || {
		echo "error(usage): no argument, no flake.lock in cwd"
		return 1
	}

	local source_file="/etc/nixos/flake.lock"

	for file in "$source_file" "$target_file"; do
		[ -f "$file" ] || {
			echo "$file not found"
			return 1
		}
	done

	while IFS= read -r -d '' input_name; do
		local input=".nodes.\"$input_name\""
		local prop="$input.locked"

		local source_has_prop=$(jq -r "$prop != null" "$source_file")
		# indirect is deprecated, but just in case:
		local indirect=$(jq -r "$input.original.type == \"indirect\"" "$target_file")
		if [ "$source_has_prop" == false ] || [ "$indirect" == true ]; then
			continue
		fi

		__jq_equals "$input.original" "$source_file" "$target_file" || {
			echo ".original mismatch on $input"
			return 1
		}

		local new_value=$(jq -r "$prop | tojson" "$source_file")
		local replace_expr="$prop = (\$arg | fromjson)"
		jq --arg arg "$new_value" "$replace_expr" "$target_file" | sponge "$target_file"
	done < <(jq --raw-output0 ".nodes | keys[]" "$target_file")

	echo "synced $target_file with system flake.lock"
}
