{
  lib,
  osConfig ? null,
  ...
}:
{
  imports = [
    ./kanshi.nix
    ./mime.nix
    ./portals.nix
    ./niri
    ./noctalia
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
