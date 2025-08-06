{ pkgs, ... }:
{
  imports = [
    ./claude.nix
    ./avante.nix
    ./gemini.nix
    ./crush.nix
    ./amp.nix
    ./goose.nix # TODO
  ];
}
