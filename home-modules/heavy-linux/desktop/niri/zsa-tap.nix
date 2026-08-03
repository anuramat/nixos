# niri has no per-device input settings, but the detachable ZSA touchpad
# (Voyager "Navigator") has no buttons, so tapping must be enabled while it's
# attached. config.kdl includes a state file that a systemd path unit rewrites
# on /dev/input changes; niri watches included files and live-reloads.
{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  tapFile = "${config.xdg.stateHome}/niri/zsa-tap.kdl";
  sync = pkgs.writeShellScript "zsa-tap-sync" ''
    tap='input {
        touchpad {
            tap
        }
    }'
    grep -q 'ZSA.*Touchpad' /proc/bus/input/devices || tap=""
    mkdir -p '${builtins.dirOf tapFile}'
    [ "$(cat '${tapFile}' 2>/dev/null)" = "$tap" ] || printf '%s\n' "$tap" > '${tapFile}'
  '';
in
# pointless on hosts where tap is statically enabled (bgm5)
lib.mkIf (!config.programs.niri.settings.input.touchpad.tap) {
  # must come after the input section: merged config is last-wins
  programs.niri.config = options.programs.niri.config.default ++ [
    (inputs.niri.lib.kdl.leaf "include" [
      { optional = true; }
      tapFile
    ])
  ];
  systemd.user = {
    services.zsa-tap = {
      Unit.Description = "Sync niri tap-to-click with ZSA touchpad presence";
      Service = {
        Type = "oneshot";
        ExecStart = "${sync}";
      };
      Install.WantedBy = [ "default.target" ];
    };
    paths.zsa-tap = {
      Path.PathChanged = "/dev/input";
      Install.WantedBy = [ "paths.target" ];
    };
  };
}
