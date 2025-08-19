{ pkgs, lib, ... }:
let
  inherit (lib) foldl' mergeAttrs;
  args = { inherit pkgs lib; };
in
foldl' mergeAttrs { } (
  map (x: import x args) [
    ./hax/mime.nix
    ./hax/web.nix
    ./hax/vim.nix
    ./hax/common.nix
    ./hax/hosts.nix
    ./hax/home.nix
    ./integration/username.nix
  ]
)
