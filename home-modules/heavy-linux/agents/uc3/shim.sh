#!/usr/bin/env bash
# in-sandbox client for the uc3 relay; zero authority

set -euo pipefail

if [ "$#" -eq 0 ] || [ "${1:-}" = help ]; then
	cat <<-'EOF'
		usage: uc3ctl [-t SECS] <command> [arg ...]

		Runs the command on bwUniCluster 3.0 and exits with its status; every
		command is logged on the host. Semantics mirror `ssh uc3 <command>`:
		the line is parsed by the cluster login shell, so quote to control
		remote-vs-local expansion (uc3ctl 'echo $HOME' expands remotely).
		stdin and stdout are streamed byte-for-byte. For multiline commands:
		    uc3ctl 'bash -s' < script.sh
		Inline heredocs (uc3ctl 'bash -s' <<EOF) and heredocs/newlines in the
		command argument are unsupported; put the script in a file instead.

		The local timeout defaults to 300s; use -t 0 for no local bound or
		raise it for big uploads and long synchronous work. Prefer sbatch and
		polling for long jobs regardless.
	EOF
	exit 0
fi

seconds=300
if [ "${1:-}" = -t ]; then
	seconds=${2:-}
	shift 2 || true
	if [[ ! $seconds =~ ^[0-9]+$ ]] || [ "$#" -eq 0 ]; then
		echo "uc3ctl: usage: uc3ctl [-t SECS] <command> [arg ...]" >&2
		exit 2
	fi
fi

sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/uc3.sock"
if [ ! -S "$sock" ]; then
	echo "uc3ctl: broker socket missing: $sock" >&2
	exit 1
fi

# Do not consume interactive terminal input as an upload.
[ ! -t 0 ] || exec </dev/null
exec uc3-client "$sock" "$seconds" "$@"
