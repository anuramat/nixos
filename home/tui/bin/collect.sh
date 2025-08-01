#!/usr/bin/env bash

filename="$1"
[[ -z $filename ]] && {
	echo "Usage: $0 <filename>" >&2
	exit 1
}

dir="$PWD"
[[ -n $2 ]] && dir=$(dirname "$(realpath -s "$2")")
files=()
while true; do
	[[ -f "$dir/$filename" ]] && files=("$dir/$filename" "${files[@]}")
	[[ $dir == "/" ]] && break
	dir="$(dirname "$dir")"
done

for file in "${files[@]}"; do cat "$file"; done
