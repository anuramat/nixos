#!/usr/bin/env bash
set -euo pipefail

mapfile -d '' -t sockets < <(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'wayland-*' -not -name '*.lock' -print0)
if [[ ${#sockets[@]} -ne 1 ]]; then
	echo "expected exactly one wayland socket, found ${#sockets[@]}" >&2
	return 1
fi
WAYLAND_DISPLAY="$(basename "${sockets[0]}")"
export WAYLAND_DISPLAY

wl-paste --no-newline 2>/dev/null || true
