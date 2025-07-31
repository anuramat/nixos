{ pkgs, ... }:
{
  imports = [
    ./amp.nix
    ./claude.nix
    ./codex.nix
    ./crush.nix
    ./gemini.nix
    ./goose.nix
    ./opencode.nix
  ];
  home.packages = with pkgs; [
    ccusage
    claude-desktop
    openai-whisper
  ];
}
