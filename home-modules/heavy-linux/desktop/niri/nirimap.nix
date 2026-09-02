{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.lib.stylix.colors.withHashtag;
  configFile = (pkgs.formats.toml { }).generate "nirimap-config.toml" {
    display = {
      anchor = "top-right";
      workspace_mode = "all";
      height = 50;
      max_width_percent = 0.5;
      max_height_percent = 0.5;
      margin_x = 50;
      margin_y = 50;
    };
    appearance = {
      background = c.base00;
      window_color = c.base03;
      focused_color = c.base0D;
      border_color = c.base04;
      border_width = 1;
      border_radius = 2;
      gap = 2;
      background_opacity = 0;
      window_opacity = 0.5;
      focused_opacity = 0.5;
      workspace_gap = 4;
      active_workspace_border_color = c.base0D;
      active_workspace_border_width = 2;
    };
    labels.enabled = false;
    icons = {
      enabled = true;
      size = "auto"; # "auto" or px
      position = "center";
      opacity = 0.5;
      min_window_size = 16; # skip on windows smaller than this
    };
    behavior = {
      always_visible = false; # show on focus change
      hide_timeout_ms = 1000;
      show_for_floating_windows = false;
    };
  };
in
{
  xdg.configFile."nirimap/config.toml".source = configFile;

  systemd.user.services.nirimap = {
    Unit = {
      After = [ config.wayland.systemd.target ];
      PartOf = [ config.wayland.systemd.target ];
      X-Restart-Triggers = [ "${configFile}" ];
    };
    Service = {
      ExecStart = lib.getExe' pkgs.nirimap "nirimap";
      Restart = "on-failure";
    };
    Install.WantedBy = [ config.wayland.systemd.target ];
  };
}
