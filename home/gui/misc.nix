{ osConfig, ... }:
{
  services = {
    blueman-applet.enable = osConfig.services.blueman.enable;
    avizo = {
      enable = true;
      settings = {
        default = {
          time = 0.5;
        };
      };
    };
    udiskie = {
      enable = osConfig.services.udisks2.enable;
      notify = true;
      tray = "auto";
      automount = true;
    };
  };
  services.network-manager-applet.enable = osConfig.networking.networkmanager.enable;
}
