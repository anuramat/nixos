{ }:
let
  internal = "eDP-1";
  external = "DP-1 DP-2 DP-3 HDMI-A-2";
in
{
  wayland.windowManager.sway.config.workspaceOutputAssign = [
    map
    {
      output = "";
      workspace = "";
    }
  ];
}
