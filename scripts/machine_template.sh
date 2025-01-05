#!/usr/bin/env bash

root="./nix/machines/$(hostname)"
mkdir -p "$root"
cat << EOF > "$root/meta.nix"
{
  builder = false;
}
EOF
cat << EOF > "$root/default.nix"
{
  system.stateVersion = null; # CHANGE ME
  imports = [
    ./hardware-configuration.nix
  ];
}
EOF
