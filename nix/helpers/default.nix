{ lib, ... }:
let
  common = import ./common.nix {
    inherit lib;
  };
in
common
// {
  web = import ./web.nix;
  mime = import ./mime.nix {
    inherit lib;
    inherit common;
  };
}
