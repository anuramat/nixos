# routes desktop notifications to wherever the user is, over ntfy: an unlocked
# peer among the `local` hosts, or the phone
{
  config,
  inputs,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  notify-forward = pkgs.writers.writePython3Bin "notify-forward" {
    libraries = with pkgs.python3Packages; [
      jeepney
      pillow
    ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./notify-forward.py);
  inherit (inputs.self.consts.ntfy) host port;
  inherit (osConfig.networking) hostName;
  peers = inputs.self.hosts |> lib.filterAttrs (n: h: h.local && n != hostName) |> lib.attrNames;
in
{
  config = lib.mkIf (osConfig != null) {
    systemd.user.services.notify-forward = {
      Unit = {
        Description = "route desktop notifications to wherever the user is";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };
      Service = {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe notify-forward)
            "http://${host}:${toString port}"
            hostName
          ]
          ++ peers
        );
        # sh and loginctl for the lock state, ssh for the peers'
        Environment = "PATH=${
          lib.makeBinPath [
            pkgs.bash
            pkgs.openssh
            pkgs.systemd
          ]
        }";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ config.wayland.systemd.target ];
    };
  };
}
