{ pkgs, ... }:
{
  home.packages = [ pkgs.swaylock-plugin ];
  programs = {
    swaylock = {
      enable = true;
      settings = {
        ignore-empty-password = true;
        indicator-caps-lock = true;
        command = "shaderbg '*' ${./windows.frag}";
      };
    };
  };
}
