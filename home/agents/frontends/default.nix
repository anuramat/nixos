{ pkgs, ... }:
{
  imports = [
    ./claude.nix
    ./avante.nix
    ./gemini.nix
    ./crush.nix
    ./codex.nix
    ./amp.nix
    ./forge.nix
    ./goose.nix # TODO
  ];
}
