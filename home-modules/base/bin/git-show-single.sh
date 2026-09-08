#!/usr/bin/env bash

file="$1"
commit="${2:-@~}"

if [[ $(git diff "$commit" @ -- "$file" | wc -l) == 0 ]]; then
	gum style --bold --foreground="#00FF00" "no changes"
	exit 0
fi

git show "$commit:$file" | bat "--file-name=$file"
