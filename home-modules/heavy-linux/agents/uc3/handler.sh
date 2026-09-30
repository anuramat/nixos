#!/usr/bin/env bash
# the uc3 relay's handler, see ../relay: runs the command on uc3
# no policy on what runs -- only auth and host-pinning

set -euo pipefail

breaker=$STATE_DIRECTORY/login-disabled

# the ssh master lives in uc3-master.service: it outlives this instance, and
# systemd serializes its starts, so parallel cold starts share one login.
# a refused login trips the breaker: a caller's retry loop must not be able to
# lock the TOTP token, so a human has to clear it
login() {
	ssh -O check uc3 2>/dev/null && return
	if [ -e "$breaker" ]; then
		echo "uc3: ERROR: logins disabled since $(<"$breaker") after a refused login; rm $breaker to re-enable" >&2
		exit 255
	fi
	systemctl --user start uc3-master && return
	cat "$STATE_DIRECTORY/login.err" >&2
	if grep -q 'Permission denied' "$STATE_DIRECTORY/login.err"; then
		date -Is >"$breaker"
		echo "uc3: ERROR: login failed; logins disabled until $breaker is removed" >&2
	else
		echo "uc3: ERROR: cluster unreachable" >&2
	fi
	exit 255
}

login
# BatchMode: never answer a prompt here; every login goes through uc3-master.
# ssh's own diagnostics already reach the caller's stderr
exec timeout 3600 ssh -o BatchMode=yes -- uc3 "$1"
