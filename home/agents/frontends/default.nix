{ pkgs, ... }:
{
  imports = [
    ./claude.nix
    ./avante.nix # TODO
    ./gemini.nix
    ./crush.nix
    ./opencode.nix # TODO

    ./codex.nix
    ./amp.nix

    ./forge.nix # TODO
    ./goose.nix # TODO

    ./codebuff.nix # TODO doesn't work: 2025-08-04
  ];

  home.packages = with pkgs; [
    ccusage
    claude-desktop
    openai-whisper
    copilot-api
  ];
}
