{ pkgs, ... }:
{
  imports = [
    ./claude.nix
    ./avante.nix
    ./gemini.nix
    ./crush.nix
    ./goose.nix # TODO
  ];
}
