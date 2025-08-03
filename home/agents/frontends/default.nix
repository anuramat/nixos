{ pkgs, ... }:
{
  imports = [
    ./claude.nix
    ./avante.nix
    ./gemini.nix
    ./crush.nix
    ./opencode.nix

    ./amp.nix
    ./codex.nix
    ./goose.nix
  ];

  home.packages = with pkgs; [
    ccusage
    claude-desktop
    openai-whisper
    copilot-api
  ];
}
