#!/usr/bin/env bash
# in-sandbox client for the uc3 relay; zero authority

set -euo pipefail

if [ "$#" -eq 0 ] || [ "${1:-}" = help ]; then
	cat <<-'EOF'
		usage: uc3ctl <command> [arg ...]

		Runs the command on bwUniCluster 3.0 and exits with its status; every
		command is logged on the host. Semantics mirror `ssh uc3 <command>`:
		the line is parsed by the cluster login shell, so quote to control
		remote-vs-local expansion (uc3ctl 'echo $HOME' expands remotely).
		stdin is streamed to the remote command (uploads); binary stdout is
		unsupported -- encode downloads, e.g. via base64.
	EOF
	exit 0
fi

sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/uc3.sock"
if [ ! -S "$sock" ]; then
	echo "uc3ctl: broker socket missing: $sock" >&2
	exit 1
fi

# a tty as stdin would hang the stream until EOF
[ ! -t 0 ] || exec </dev/null
out="$({
	printf '%s\n' "$*"
	cat
} | socat -t 3700 - "UNIX-CONNECT:$sock")"
if [[ ! $out =~ --uc3-exit:([0-9]+)--$ ]]; then
	echo "uc3ctl: protocol error: missing exit trailer" >&2
	exit 1
fi
printf '%s' "${out%--uc3-exit:*}"
exit "${BASH_REMATCH[1]}"
