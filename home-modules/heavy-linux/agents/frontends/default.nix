{ pkgs, ... }:
{
  imports = [
    ./avante.nix
    ./claude.nix
    ./codex.nix
    ./cursor.nix
    ./forge.nix
    ./gemini.nix
    ./goose.nix
    ./opencode.nix
  ];
}
