{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.stylix
    inputs.niri.homeModules.niri
    ./keys.nix
    ./bar.nix
  ];
  systemd.user.targets.niri-session = {
    Unit = {
      Description = "Niri session";
      # Requires = [ "graphical-session.target" ];
      # After = [ "graphical-session.target" ];
    };
  };
  # TODO parameterize and move out
  wayland.systemd.target =
    let
      name = "niri-session";
    in
    if config.systemd.user.targets ? ${name} then
      "${name}.target"
    else
      throw "target ${name} not found";
  services.gnome-keyring.enable = lib.mkForce false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      screenshot-path = "${config.home.sessionVariables.XDG_PICTURES_DIR}/screen/shot_%F_%T.png";
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;
    };
  };
}
