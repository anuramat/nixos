#!/usr/bin/env bash
# usage: fleet-poll NAME INTERVAL CMD...
# runs CMD every INTERVAL seconds, or right away on SIGUSR1 (with REFRESH=1),
# and merges its output, a section object (see default.nix), into
# $STATE_DIRECTORY/NAME.json; on failure, or without output, it keeps the last
# rows and sets `err` to the last line of CMD's stderr

set -euo pipefail

f=$STATE_DIRECTORY/$1.json interval=$2
shift 2
[ -e "$f" ] || echo '{}' >"$f"
refresh=
trap 'refresh=1' USR1
while :; do
	r=$refresh refresh=
	# a hung command (e.g. a stuck ssh) would stall the section for good
	if ! out=$(REFRESH=$r timeout 60 "$@" 2>"$f.err") || [ "$out" = "" ]; then
		# ssh ends its messages with \r\n
		out=$(jq -n --arg e "$(tail -n 1 "$f.err")" '{err: ($e | rtrimstr("\r") | if . == "" then "failed" end)}')
	fi
	# `at` is when the rows were fetched, unless CMD knows better
	jq -c --argjson new "$out" --argjson now "$(date +%s)" \
		'. + {err: null} + (if $new | has("children") then {at: $now} else {} end) + $new' "$f" >"$f.tmp"
	mv "$f.tmp" "$f"
	[ "$refresh" = "" ] || continue
	sleep "$interval" &
	# cut short by SIGUSR1
	wait $! || kill $! 2>/dev/null || :
done
