{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  fleetStatus = pkgs.callPackage ./fleet-status.nix { inherit inputs; };
  widget = {
    type = "anuramat/fleet-monitor:jobs";
    settings.font_size = 32;
  };
in
{
  home.packages = [ fleetStatus ];

  # local plugins are scanned from here and activated by `plugins.enabled`
  xdg.dataFile = {
    "noctalia/plugins/fleet-monitor/plugin.toml".source =
      (pkgs.formats.toml { }).generate "plugin.toml"
        {
          id = "anuramat/fleet-monitor";
          name = "Fleet monitor";
          plugin_api = 23;
          desktop_widget = [
            {
              id = "jobs";
              entry = "widget.luau";
              # minimum card size in logical px, and the font size, which the
              # rest of the layout scales with (14 is noctalia's default);
              # unlike the widget box (`box_width`, `box_height`), which scales
              # the content to fit it, these keep the font size fixed
              setting =
                lib.mapAttrsToList
                  (key: default: {
                    inherit key default;
                    type = "int";
                    label_key = key;
                  })
                  {
                    width = 0;
                    height = 0;
                    font_size = 14;
                  };
            }
          ];
          # polls once for every widget instance (desktop and lockscreen)
          service = [
            {
              id = "poller";
              entry = "service.luau";
            }
          ];
        };
    "noctalia/plugins/fleet-monitor/widget.luau".source = ./widget.luau;
    "noctalia/plugins/fleet-monitor/service.luau".source = pkgs.replaceVars ./service.luau {
      exe = lib.getExe fleetStatus;
      hosts = lib.generators.toLua { } fleetStatus.hosts;
      uc3state = config.lib.uc3.stateDir;
      systemctl = lib.getExe' pkgs.systemd "systemctl";
    };
  };

  programs.noctalia.settings = {
    plugins.enabled = [ "anuramat/fleet-monitor" ];
    # geometry is set per host (logical px of its display); without `output`,
    # noctalia uses the first output instead of a host-specific connector
    desktop_widgets.widget.fleet = widget;
    lockscreen_widgets.widget.fleet = widget;
  };
}
