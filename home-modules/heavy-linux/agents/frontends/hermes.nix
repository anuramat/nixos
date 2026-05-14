{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hermes
  ];
}
