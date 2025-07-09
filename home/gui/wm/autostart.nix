{ lib, pkgs, ... }:
{
  wayland.windowManager.sway = {
    systemd.xdgAutostart = true;
    config.startup = [
      {
        # <https://github.com/nix-community/home-manager/issues/2797>
        command = "${pkgs.kanshi}/bin/kanshictl reload";
        always = true;
      }
      # {
      #   # shouldn't be necessary but sometimes waybar bugs out
      #   command = "pgrep waybar || systemctl restart --user waybar.service";
      #   always = true;
      # }
    ];
  };

  systemd.user.services = {
    wl-clip-persist =
      let
        # TODO target
        target = "graphical-session.target";
      in
      {
        Unit = {
          Description = "Persistent clipboard for Wayland";
          PartOf = [ target ];
          After = [ target ];
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.wl-clip-persist} --clipboard regular";
          Restart = "always";
        };
        Install.WantedBy = [ target ];
      };
  };
}
