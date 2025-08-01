{ pkgs, ... }:
{
  # checklist: instructions, context files, roles, mcp, lsp, commands
  imports = [
    ./amp.nix # ?
    ./avante.nix # TODO: mcp, commands, roles
    ./claude.nix # TODO: CLAUDE.md is hardcoded
    ./codex.nix # ?
    ./crush.nix # roles, commands
    ./gemini.nix # TODO commands, subasians, mcp
    ./goose.nix # TODO all
    ./opencode.nix # TODO mcp subasians commands lsp
  ];
  home.packages = with pkgs; [
    ccusage
    claude-desktop
    openai-whisper
  ];
}
