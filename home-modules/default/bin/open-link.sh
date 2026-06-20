#!/usr/bin/env bash
set -euo pipefail

mapfile -d '' -t sockets < <(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'niri.wayland*.sock' -print0)
if [[ ${#sockets[@]} -ne 1 ]]; then
	echo "expected exactly one niri socket, found ${#sockets[@]}" >&2
	exit 1
fi
NIRI_SOCKET="${sockets[0]}"
export NIRI_SOCKET

# this doesn't work because firefox isn't in path on niri:
# browser=$(xdg-settings get default-web-browser)
# "$(command -v gtk-launch)" "$browser" "$1"

niri msg action spawn -- "$(command -v firefox)" "$1"
