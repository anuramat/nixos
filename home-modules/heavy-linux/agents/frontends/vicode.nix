{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (vicode.overrideAttrs { doCheck = false; })

  ];
}
