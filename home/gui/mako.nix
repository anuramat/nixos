{ config, ... }:
let
  c = config.lib.stylix.colors.withHashtag;
in
{
  services.mako = {
    enable = true;
    settings = {
      default-timeout = "0";
      layer = "overlay";
      anchor = "top-center";
      text-alignment = "center";
      output = "eDP-1";
      "app-name=Spotify" = {
        invisible = "1";
      };
    };
  };
}
