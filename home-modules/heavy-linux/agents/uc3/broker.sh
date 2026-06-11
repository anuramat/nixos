#!/usr/bin/env bash
# host side of the uc3 relay; one instance per connection (systemd Accept=yes)
# no policy on what runs -- only auth, host-pinning, and logging

set -euo pipefail

IFS= read -r cmd || exit 0
{
	# command lines are unbounded and may exceed PIPE_BUF
	flock 9
	printf '%s\t%s\n' "$(date -Is)" "$cmd" >&9
} 9>>"$STATE_DIRECTORY/commands.log"

rc=0
SSH_ASKPASS=uc3-askpass SSH_ASKPASS_REQUIRE=force \
	timeout 3600 ssh -o ConnectTimeout=15 uc3 -- "$cmd" 2>&1 || rc=$?
[ "$rc" -ne 255 ] || echo "uc3: ERROR: cluster unreachable"
printf -- '--uc3-exit:%s--\n' "$rc"
