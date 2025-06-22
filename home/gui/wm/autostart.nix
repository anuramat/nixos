{ lib, pkgs, ... }:
{
  wayland.windowManager.sway = {
    systemd.xdgAutostart = true;
    config.startup =
      let
        clip = lib.getExe pkgs.wl-clip-persist;
        killall = lib.getExe pkgs.killall;
      in
      [
        {
          # TODO maybe use a different clipboard manager?
          command = "${killall} wl-clip-persist || ${clip} --clipboard regular";
          always = true;
        }
        {
          # <https://github.com/nix-community/home-manager/issues/2797>
          command = "${pkgs.kanshi}/bin/kanshictl reload";
          always = true;
        }
      ];
  };
}
