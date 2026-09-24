{ lib, pkgs, ... }:
{
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # wayland chromium/electron
    TERMCMD = "${lib.getExe pkgs.foot}";
    # TERMCMD = "${lib.getExe pkgs.ghostty}";
    # TERMCMD = "${lib.getExe pkgs.kitty} -1";
  };
  programs.ghostty.settings = {
    command = "bash -l";
    window-decoration = "false";
  };
  programs.foot = {
    enable = true;
    settings = {
      main.login-shell = "yes";
      scrollback.lines = 133337;
      url = {
        osc8-underline = "always";
        launch = "bash -lc 'exec xdg-open \"$1\"' foot-url \${url}"; # login shell: niri's PATH is minimal
      };
      bell = {
        urgent = "yes";
        visual = "yes";
        notify = "no";
      };
      key-bindings = {
        show-urls-copy = "Control+Shift+y";
        scrollback-home = "Shift+Home";
        scrollback-end = "Shift+End";
      };
    };
  };
}
