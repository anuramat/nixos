{ pkgs, ... }:
{
  imports = [
    ./codex.nix
    ./claude.nix
    ./avante.nix
    ./gemini.nix
    ./crush.nix
    ./goose.nix # TODO
  ];
}
