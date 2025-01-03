#!/usr/bin/env bash

fail_color="$(tput setaf 1 bold)"
ok_color="$(tput setaf 2 bold)"
normal_color="$(tput sgr0)"

shrun() {
	# pretty-runs a file linter/formatter on all sh files
	local -r command="$1"

	# find all shell scripts
	fd -HL -t f -0 . | while IFS= read -r -d '' filename; do
		head -n 1 "$filename" | grep -q "^#!.*sh" || echo "$filename" | grep -iq "sh$" && printf '%s\0' "$filename"
	done | while IFS= read -r -d '' filename; do
		# print the filename
		printf %s "$filename"
		# run the command, outputting status to the right of the filename
		result="$($command "$filename")" \
			&& printf "$ok_color%$(($(tput cols) - 2 - ${#filename}))s\r$normal_color" "OK" \
			|| printf "$fail_color%$(($(tput cols) - 1 - ${#filename}))s\r$normal_color" "FAIL"
		echo ''
		# print the results of the command (if any)
		[ -n "$result" ] && echo "$result"
	done
}

type=$1
shift

case "$type" in
	silent)
		shrun "$@" > /dev/null
		;;
	verbose)
		shrun "$@"
		;;
	*)
		echo "$0: illegal arguments"
		exit 1
		;;
esac

exit 0
