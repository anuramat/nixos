#!/usr/bin/env bash
# uc3pull REMOTE_PATH [LOCAL_DIR=.]
# Pull a file or directory from uc3 via croc (bypasses the VPN: ~40 MB/s vs
# ~1 MB/s through the uc3ctl relay), then verify every file's md5 against the
# remote. REMOTE_PATH is absolute or relative to the cluster home (no trailing
# slash); the object lands inside LOCAL_DIR under its own basename.
set -euo pipefail
src=$1 dst=${2:-.}
code=pull-$(head -c 9 /dev/urandom | base32 | tr '[:upper:]' '[:lower:]')
sums=$(mktemp) && trap 'rm -f "$sums"' EXIT
uc3ctl -t 0 "CROC_SECRET=$code nohup ~/.local/bin/croc --yes send $src </dev/null >/tmp/croc_send_\$USER.log 2>&1 &
  cd \$(dirname $src) && find \$(basename $src) -type f -exec md5sum {} + | sort -k2" >"$sums"
mkdir -p "$dst"
CROC_SECRET=$code croc --yes --out "$dst" || {
	uc3ctl 'pkill -u $USER -f "[c]roc --yes send"'
	exit 1
}
(cd "$dst" && find "$(basename "$src")" -type f -exec md5sum {} + | sort -k2) | diff - "$sums" \
	&& echo "verified $(wc -l <"$sums") file(s) -> $dst/$(basename "$src")"
