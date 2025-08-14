{ pkgs, lib, ... }:
let
  inherit (lib) foldl' mergeAttrs;
  args = { inherit pkgs lib; };
in
foldl' mergeAttrs { } (
  map (x: import x args) [
    ./unit/hax/hosts.nix
    ./unit/hax/mime.nix
    ./unit/hax/web.nix
    ./unit/hax/vim.nix
    ./unit/hax/common.nix
    ./unit/hax/text.nix
    ./unit/hax/utils.nix
    ./unit/hax/config.nix
    ./unit/hax/shell.nix
  ]
)
