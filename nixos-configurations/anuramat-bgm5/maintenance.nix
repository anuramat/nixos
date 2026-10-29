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
      hm.lib.tgfy.package
    ];
    text = builtins.readFile ./nixpkgs-bump.sh;
  };
  nixpkgs-cves = pkgs.writers.writePython3Bin "nixpkgs-cves" {
    flakeIgnore = [ "E501" ]; # black owns line length
  } ./nixpkgs-cves.py;
in
{
  systemd = {
    services = {
      # weekly stable bump, built here so the other hosts only download it
      nixpkgs-bump = {
        startAt = "Sat 04:00";
        serviceConfig = {
          Type = "oneshot";
          User = username;
          StateDirectory = "nixpkgs-bump";
          ExecStart = "${lib.getExe nixpkgs-bump} /etc/nixos /var/lib/nixpkgs-bump";
        };
        # report new security tracker issues that affect the freshly built bump
        onSuccess = [ "nixpkgs-cves.service" ];
      };
      nixpkgs-cves = {
        path = [
          config.nix.package
          hm.lib.tgfy.package
        ];
        serviceConfig = {
          Type = "oneshot";
          User = username;
          StateDirectory = "nixpkgs-cves";
          ExecStart = "${lib.getExe nixpkgs-cves} /var/lib/nixpkgs-cves /var/lib/nixpkgs-bump ${config.system.nixos.release}";
        };
      };
    };
    timers.nixpkgs-bump.timerConfig.Persistent = true;
  };
}
