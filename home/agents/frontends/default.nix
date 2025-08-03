{ pkgs, ... }:
{
  # checklist: instructions, context files, roles, mcp, lsp, commands
  # ./amp.nix # ?
  # ./avante.nix # TODO: mcp, commands, roles
  # ./claude.nix # TODO: CLAUDE.md is hardcoded
  # ./codex.nix # ?
  # ./crush.nix # roles, commands
  # ./gemini.nix # TODO commands, subasians, mcp
  # ./goose.nix # TODO all
  # ./opencode.nix # TODO mcp subasians commands lsp

  imports = [
    ./amp.nix
    ./avante.nix
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
    copilot-api
  ];
}
