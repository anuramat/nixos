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
    ./menu.nix
    ./mime
    ./portals.nix
    ./niri
    ./swaylock.nix
    ./syncthing.nix
  ];
  config = lib.mkMerge [
    # NOTE ashell subsumes avizo's OSD and the network/bluetooth applets; see
    # ./niri/ashell.nix
    { home.packages = with pkgs; [ shaderbg ]; }
    (lib.mkIf (osConfig != null) {
      services.udiskie = {
        enable = osConfig.services.udisks2.enable;
        notify = true;
        tray = "auto";
        automount = true;
      };
    })
  ];
}
