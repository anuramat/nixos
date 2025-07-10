{
  lib,
  pkgs,
  config,
  ...
}:
{
  # TODO are all fields required?
  systemd.user.services.wl-clip-persist =
    let
      inherit (config.wayland.systemd) target;
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
}
