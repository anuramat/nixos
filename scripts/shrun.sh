#!/usr/bin/env bash

get_scripts() {
	# find all shell scripts and run a command
	fd -HL -t f -0 . | while IFS= read -r -d '' filename; do
		if head -n 1 "$filename" | grep -q "^#!.*sh" || echo "$filename" | grep -iq "sh$"; then
			printf '%s\0' "$filename"
		fi
	done
}

case "$1" in
	shfmt)
		get_scripts | xargs -0 -L 1 "$@"
		;;
	shellcheck)
		get_scripts | xargs -0 "$@"
		;;
	*)
		echo "$0: illegal arguments"
		exit 1
		;;
esac

exit 0
