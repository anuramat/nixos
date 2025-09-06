{ pkgs, ... }:
{
  imports = [
    ./avante.nix
    ./claude.nix
    ./codex.nix
    ./crush.nix
    ./cursor.nix
    ./forge.nix
    ./gemini.nix
    ./goose.nix
    ./opencode.nix
    ./qwen.nix
  ];
}
