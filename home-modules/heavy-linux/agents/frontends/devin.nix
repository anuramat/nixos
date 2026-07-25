{ pkgs, ... }:
{
  home.packages = with pkgs; [
    devin-cli
  ];
}
