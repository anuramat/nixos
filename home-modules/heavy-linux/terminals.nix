{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.wayland.systemd) target;
in
{
  programs.ghostty.settings.window-decoration = "false";
  programs.foot = {
    enable = true;
    settings = {
      scrollback.lines = 133337;
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

  systemd.user.services.kitty-autostart = {
    Unit = {
      Description = "Autostart Kitty terminal";
      PartOf = [ target ];
      After = [ target ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.kitty} --start-as=hidden -1";
    };
    Install.WantedBy = [ target ];
  };
}
