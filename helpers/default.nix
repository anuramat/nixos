{ lib, ... }@args:
rec {
  common = import ./common.nix args;
  web = import ./web.nix;
  mime = import ./mime.nix args;
  hosts = import ./hosts.nix args;
}
