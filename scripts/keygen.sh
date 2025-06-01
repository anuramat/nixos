#!/usr/bin/env bash
set -e

private=/etc/nix/cache.pem
public=/etc/nix/cache.pem.pub
[ ! -e "$private" ] && [ ! -e "$public" ] \
	&& sudo nix-store --generate-binary-cache-key "$(hostname)" "$private" "$public"

sudo chown builder:builder "$private" "$public" # TODO hide somewhere in nix

[ ! -e "$HOME/.ssh" ] && yes '' | ssh-keygen -N ''

# TODO root ssh config
