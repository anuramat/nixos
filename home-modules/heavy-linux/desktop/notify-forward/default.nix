# forwards desktop notifications to the phone with tgfy while the session is locked
{
  config,
  lib,
  pkgs,
  ...
}:
let
  notify-forward = pkgs.writers.writePython3Bin "notify-forward" {
    libraries = [ pkgs.python3Packages.jeepney ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./notify-forward.py);
  systemctl = action: "systemctl --user ${action} notify-forward.service";
in
{
  options.notifyForward = lib.mkEnableOption "forwarding notifications to telegram while locked";

  config = lib.mkIf config.notifyForward {
    systemd.user.services.notify-forward = {
      Unit.Description = "forward desktop notifications to telegram";
      Service.ExecStart = "${lib.getExe notify-forward} ${lib.getExe config.lib.tgfy.package}";
    };
    programs.noctalia.settings.hooks = {
      session_locked = [ (systemctl "start") ];
      session_unlocked = [ (systemctl "stop") ];
    };
  };
}
