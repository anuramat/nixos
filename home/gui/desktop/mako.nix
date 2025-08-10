{ config, ... }:
{
  services.mako = {
    enable = true;
    settings = {
      default-timeout = "0";
      layer = "overlay";
      anchor = "top-center";
      text-alignment = "center";
      group-by = "app-name";
    };
  };
}
