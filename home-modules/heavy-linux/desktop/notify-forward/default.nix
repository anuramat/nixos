# forwards desktop notifications to the phone with ntfy while the session is locked
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  notify-forward = pkgs.writers.writePython3Bin "notify-forward" {
    libraries = [ pkgs.python3Packages.jeepney ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./notify-forward.py);
  inherit (inputs.self.consts.ntfy) host port;
  systemctl = action: "systemctl --user ${action} notify-forward.service";
in
{
  options.notifyForward = lib.mkEnableOption "forwarding notifications to ntfy while locked";

  config = lib.mkIf config.notifyForward {
    systemd.user.services.notify-forward = {
      Unit.Description = "forward desktop notifications to ntfy";
      Service.ExecStart = "${lib.getExe notify-forward} http://${host}:${toString port}/notify-forward";
    };
    programs.noctalia.settings.hooks = {
      session_locked = [ (systemctl "start") ];
      session_unlocked = [ (systemctl "stop") ];
    };
  };
}
