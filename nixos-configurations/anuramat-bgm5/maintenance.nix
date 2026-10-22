{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs.self.consts.user) username;
  hm = config.home-manager.users.${username};
  nixpkgs-bump = pkgs.writeShellApplication {
    name = "nixpkgs-bump";
    runtimeInputs = with pkgs; [
      config.nix.package
      git
      jq
      curl # for tgfy
      hm.home.path # tgfy
    ];
    text = builtins.readFile ./nixpkgs-bump.sh;
  };
in
{
  # weekly stable bump, built here so the other hosts only download it
  systemd.services.nixpkgs-bump = {
    startAt = "Sat 04:00";
    serviceConfig = {
      Type = "oneshot";
      User = username;
      StateDirectory = "nixpkgs-bump";
      ExecStart = "${lib.getExe nixpkgs-bump} /etc/nixos /var/lib/nixpkgs-bump";
    };
  };
  systemd.timers.nixpkgs-bump.timerConfig.Persistent = true;

  nix.gc = {
    automatic = true;
    dates = "Sun 04:00";
    options = "--delete-older-than 30d";
  };
}
