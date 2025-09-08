{ pkgs, ... }:
{
  imports = [
    ./avante.nix
    ./claude.nix
    ./codex.nix
    ./crush.nix
    ./gemini.nix
    ./goose.nix
    ./opencode.nix
    ./qwen.nix
  ];
}
