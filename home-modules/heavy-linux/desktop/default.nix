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
  config = lib.mkIf (osConfig != null) {
    services.udiskie = {
      enable = osConfig.services.udisks2.enable;
      notify = true;
      tray = "auto";
      automount = true;
    };
  };
}
