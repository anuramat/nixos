#!/usr/bin/env bash
# run by uc3-status.service: snapshot of the cluster for the fleet monitor and
# the terminal -- `sinfo_t_idle`, a `---` line, then our jobs as
# `ID|PARTITION|STATE|TIME|LIMIT|REASON|NAME`; a failed fetch keeps the
# previous snapshot

set -euo pipefail

uc3ctl 'sinfo_t_idle && echo --- && squeue --me -h -o "%i|%P|%T|%M|%l|%R|%j"' >"$STATE_DIRECTORY/status.tmp"
mv "$STATE_DIRECTORY/status.tmp" "$STATE_DIRECTORY/status"
