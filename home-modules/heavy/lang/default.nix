{ config, ... }:
{
  programs.go = {
    enable = true;
    env.GOPATH = "${config.xdg.cacheHome}/go";
  };
  imports = [
    ./nix.nix
    ./packages.nix
    ./python.nix
    ./yaml.nix
  ];
}
