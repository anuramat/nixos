{ pkgs, ... }:
{
  imports = [
    ./claude.nix
    ./avante.nix
    ./gemini.nix
    ./crush.nix
    ./codex.nix
    ./amp.nix
    ./forge.nix # TODO
    ./goose.nix # TODO
  ];

  home.packages = with pkgs; [
    ccusage
    claude-desktop
    openai-whisper
    copilot-api
  ];
}
