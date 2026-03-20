{ pkgs, ... }:
{
  programs.ghostty.settings = {
    command = "${pkgs.bash}/bin/bash -l";
    window-decoration = "false";
  };
  programs.foot = {
    enable = true;
    settings = {
      main.login-shell = "yes";
      scrollback.lines = 133337;
      url = {
        osc8-underline = "always";
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
