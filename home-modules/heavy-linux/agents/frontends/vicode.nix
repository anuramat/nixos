{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vicode
  ];
}
