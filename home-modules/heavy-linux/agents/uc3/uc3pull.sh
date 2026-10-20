#!/usr/bin/env bash
# uc3pull REMOTE_PATH [LOCAL_DIR=.]
# Pull a file or directory from uc3 via croc (bypasses the VPN: ~40 MB/s vs
# ~1 MB/s through the uc3ctl relay), then verify every file's md5 against the
# remote. REMOTE_PATH is absolute or relative to the cluster home (no trailing
# slash); the object lands inside LOCAL_DIR under its own basename.
set -euo pipefail
src=$1 dst=${2:-.}
# croc names the relay room after the code's first 4 characters, so those have
# to be random, or concurrent pulls end up in the same room
code=$(head -c 10 /dev/urandom | base32 | tr '[:upper:]' '[:lower:]')
sums=$(mktemp) && trap 'rm -f "$sums"' EXIT
# the code goes in over stdin, since the login node shows every user's command
# lines, and the sender's output, which repeats it, is dropped; --no-local: the
# receiver is never on the cluster's network, and concurrent senders on one
# login node would share the first one's local relay; prints the sender's PID,
# then the remote md5 sums
uc3ctl -t 0 "read -r CROC_SECRET || exit; export CROC_SECRET; nohup ~/.local/bin/croc --yes send --no-local $src </dev/null >/dev/null 2>&1 & echo \$!
  cd \$(dirname $src) && find \$(basename $src) -type f -exec md5sum {} + | sort -k2" <<<"$code" >"$sums"
read -r pid <"$sums" && sed -i 1d "$sums"
mkdir -p "$dst"
CROC_SECRET=$code croc --yes --out "$dst" || {
	uc3ctl "kill $pid"
	exit 1
}
(cd "$dst" && find "$(basename "$src")" -type f -exec md5sum {} + | sort -k2) | diff - "$sums" \
	&& echo "verified $(wc -l <"$sums") file(s) -> $dst/$(basename "$src")"
