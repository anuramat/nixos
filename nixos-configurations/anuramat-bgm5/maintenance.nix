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
  nixpkgs-cves = pkgs.writers.writePython3Bin "nixpkgs-cves" {
    flakeIgnore = [ "E501" ]; # black owns line length
  } ./nixpkgs-cves.py;
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

  # report new security tracker issues that affect the freshly built bump
  systemd.services.nixpkgs-bump.onSuccess = [ "nixpkgs-cves.service" ];
  systemd.services.nixpkgs-cves = {
    path = [
      config.nix.package
      pkgs.curl # for tgfy
      hm.home.path # tgfy
    ];
    serviceConfig = {
      Type = "oneshot";
      User = username;
      StateDirectory = "nixpkgs-cves";
      ExecStart = "${lib.getExe nixpkgs-cves} /var/lib/nixpkgs-cves /var/lib/nixpkgs-bump ${config.system.nixos.release}";
    };
  };
}
