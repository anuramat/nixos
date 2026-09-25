{ config, lib, ... }:
{
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # wayland chromium/electron
    TERMCMD = "${lib.getExe config.programs.ghostty.package}";
    # TERMCMD = "${lib.getExe pkgs.kitty} -1";
  };
  programs.ghostty.settings = {
    command = "bash -l";
    window-decoration = "false";
  };
}
