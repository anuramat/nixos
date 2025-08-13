{ pkgs, lib, ... }:
let
  inherit (lib) foldl' attrValues mergeAttrs;
in
foldl' mergeAttrs { } [
  (import ./unit/hax/hosts.nix { inherit pkgs lib; })
  (import ./unit/hax/mime.nix { inherit pkgs lib; })
  (import ./unit/hax/web.nix { inherit pkgs lib; })
  (import ./unit/hax/vim.nix { inherit pkgs lib; })
  (import ./unit/hax/common.nix { inherit pkgs lib; })
]
