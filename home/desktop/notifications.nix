{ config, ... }:
let
  c = config.lib.stylix.colors.withHashtag;
in
{
  services.mako = {
    enabled = true;
    settings = {
      default-timeout = "0";
      layer = "overlay";
      anchor = "top-center";
      text-alignment = "center";
      output = "eDP-1";
      background-color = "${c.base00}";
      text-color = "${c.base01}";
      border-color = "${c.base01}";
      "urgency=low" = {
        border-color = "${c.base01}";
      };
      "urgency=normal" = {
        border-color = "${c.base01}";
      };
      "urgency=high" = {
        border-color = "#000000";
        background-color = "#FFFF00";
        text-color = "#000000";
      };
      "app-name=Spotify" = {
        invisible = "1";
      };
    };
  };
}
