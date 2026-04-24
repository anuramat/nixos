{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;
  pkill = "${pkgs.procps}/bin/pkill";
in
{
  home.packages = [ pkgs.swaylock-plugin ];
  programs = {
    swaylock = {
      enable = true;
      settings = {
        ignore-empty-password = true;
        indicator-caps-lock = true;
        command = "${getExe pkgs.shaderbg} '*' ${./windows.frag}";
      };
    };
  };
  lib.lockscreen = {
    lock =
      pkgs.writeShellScript "lock" ''
        ${getExe config.lib.keyring.lock} || true
        ${getExe pkgs.swaylock-plugin} -f
      ''
      |> toString;
    unlock =
      pkgs.writeShellScript "unlock" ''
        ${pkill} -SIGUSR1 -x .swaylock-plugi
      ''
      |> toString;
  };
}
