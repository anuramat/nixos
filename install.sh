#!/usr/bin/env bash
set -e

. ./lib/install.sh
. ./home/.profile

echo '[cfg] installing $HOME'
shopt -s dotglob
for __dotfile in home/*; do
	install2folder "$__dotfile" "$HOME"
done
echo '[cfg] installing $XDG_CONFIG_HOME'
for __folder in config/*; do
	install2folder "$__folder" "$XDG_CONFIG_HOME"
done
shopt -u dotglob

echo "[cfg] creating directories"
# TODO move all of this to configuration.nix or home manager
touch "$HOME/.hushlogin"
ensure_path "$HOME/screenshots"
# TODO maybe ensure path for all xdg paths
