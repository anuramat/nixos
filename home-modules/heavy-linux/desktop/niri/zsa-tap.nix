# niri has no per-device input settings, but the detachable ZSA touchpad
# (Voyager "Navigator") has no buttons, so tapping must be enabled while it's
# attached. config.kdl ends with an include of a state file that a systemd path
# unit rewrites on /dev/input changes; niri watches included files and
# live-reloads. An included touchpad section replaces the main config's
# wholesale, so the fragment repeats all rendered touchpad settings.
{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (inputs.niri.lib) kdl;
  base = options.programs.niri.config.default;
  find = name: lib.findFirst (n: n.name == name) (throw "no ${name} section");
  touchpad = find "touchpad" (find "input" base).children;
  tapOn = pkgs.runCommand "zsa-tap-on.kdl" {
    config = kdl.serialize.nodes [
      (kdl.plain "input" [ (touchpad // { children = touchpad.children ++ [ (kdl.flag "tap") ]; }) ])
    ];
    passAsFile = [ "config" ];
    nativeBuildInputs = [ config.programs.niri.package ];
  } "niri validate -c $configPath && cp $configPath $out";
  tapFile = "${config.xdg.stateHome}/niri/zsa-tap.kdl";
  sync = pkgs.writeShellScript "zsa-tap-sync" ''
    tap="$(cat ${tapOn})"
    grep -q 'ZSA.*Touchpad' /proc/bus/input/devices || tap=""
    mkdir -p '${builtins.dirOf tapFile}'
    [ "$(cat '${tapFile}' 2>/dev/null)" = "$tap" ] || printf '%s\n' "$tap" > '${tapFile}'
  '';
in
# pointless on hosts where tap is statically enabled (bgm5)
lib.mkIf (!config.programs.niri.settings.input.touchpad.tap) {
  # must come after the input section: merged config is last-wins
  programs.niri.config = base ++ [
    (kdl.leaf "include" [
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
