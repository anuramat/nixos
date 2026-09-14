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

# the ssh master lives in uc3-master.service: it outlives this instance, and
# systemd serializes its starts, so parallel cold starts share one login
login() {
	ssh -O check uc3 2>/dev/null && return
	systemctl --user start uc3-master && return
	echo "uc3: ERROR: cluster unreachable"
	rc=255
	exit
}

log START "$cmd"

login
rc=0
# BatchMode: never answer a prompt here; every login goes through uc3-master
timeout 3600 ssh -o BatchMode=yes -- uc3 "$cmd" 2>&1 || rc=$?
[ "$rc" -ne 255 ] || echo "uc3: ERROR: cluster unreachable"
