{
  lib,
  osConfig ? null,
  ...
}:
{
  imports = [
    ./kanshi.nix
    ./autologin.nix
    ./menu.nix
    ./mime
    ./portals.nix
    ./niri
    ./syncthing.nix
  ];
  # NOTE noctalia subsumes avizo's OSD and the network/bluetooth applets; see
  # ./niri/noctalia.nix
  config = lib.mkIf (osConfig != null) {
    services.udiskie = {
      enable = osConfig.services.udisks2.enable;
      notify = true;
      tray = "auto";
      automount = true;
    };
  };
}
