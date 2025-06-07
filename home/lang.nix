{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # linters {{{1
    checkmake # makefile
    deadnix # nix dead code
    golangci-lint # go
    luajitPackages.luacheck # lua
    shellcheck # *sh
    statix # nix
    yamllint
  ];
}
