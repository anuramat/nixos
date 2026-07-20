#!/usr/bin/env bash
# host side of the uc3 relay; one instance per connection (systemd Accept=yes)
# no policy on what runs -- only auth, host-pinning, and logging

set -euo pipefail

IFS= read -r cmd || exit 0

started=$EPOCHSECONDS
id=$$-$started
rc=1
log() {
	local event=$1
	shift
	{
		# command lines are unbounded and may exceed PIPE_BUF
		flock 9
		printf '%s\t%s\t%s' "$(date -Is)" "$event" "$id" >&9
		printf '\t%s' "$@" >&9
		printf '\n' >&9
	} 9>>"$STATE_DIRECTORY/commands.log"
}
finish() {
	trap - EXIT
	set +e
	printf -- '--uc3-exit:%s--\n' "$rc"
	log END "rc=$rc" "dur=$((EPOCHSECONDS - started))s"
}
trap finish EXIT

log START "$cmd"

rc=0
SSH_ASKPASS=uc3-askpass SSH_ASKPASS_REQUIRE=force \
	timeout 3600 ssh -o ConnectTimeout=15 -- uc3 "$cmd" 2>&1 || rc=$?
[ "$rc" -ne 255 ] || echo "uc3: ERROR: cluster unreachable"
