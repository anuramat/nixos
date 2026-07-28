{
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
{
  imports = [
    ./kanshi.nix
    ./autologin.nix
    ./clipboard.nix
    ./mako.nix
    ./menu.nix
    ./mime
    ./portals.nix
    ./niri
    ./swaylock.nix
    ./syncthing.nix
  ];
  config = lib.mkMerge [
    {
      home.packages = with pkgs; [ shaderbg ];
      services.avizo = {
        enable = true;
        settings.default.time = 0.5;
      };
    }
    (lib.mkIf (osConfig != null) {
      services = {
        blueman-applet.enable = osConfig.services.blueman.enable;
        udiskie = {
          enable = osConfig.services.udisks2.enable;
          notify = true;
          tray = "auto";
          automount = true;
        };
        network-manager-applet.enable = osConfig.networking.networkmanager.enable;
      };
      systemd.user.services.network-manager-applet.Service.Restart =
        lib.mkIf osConfig.networking.networkmanager.enable "on-failure";
    })
  ];
}
