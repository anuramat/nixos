{ pkgs, ... }:
{
  imports = [
    ./codex.nix
    ./claude.nix
    ./avante.nix
    ./gemini.nix
    ./goose.nix # TODO
    ./cursor.nix
  ];
}
