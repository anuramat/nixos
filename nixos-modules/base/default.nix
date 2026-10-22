{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./agent.nix
    ./builder.nix
    ./external_keys.nix
    ./home.nix
    ./hosts.nix
    ./net.nix
    ./nix.nix
    ./user.nix
    ./web.nix
    ./rocm.nix
    ./cuda.nix

    inputs.agenix.nixosModules.default
    inputs.self.sharedModules.age
    inputs.self.sharedModules.nixpkgs
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    users.${inputs.self.consts.user.username} = {
      imports = with inputs.self.homeModules; [
        base
        linux
      ];
      home.stateVersion = lib.mkDefault config.system.stateVersion;
    };
  };

  i18n.defaultLocale = inputs.self.consts.user.locale;
  time.timeZone = inputs.self.consts.user.timeZone;
  # `nixos-version --configuration-revision`
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  # udev autoloads it next to `button` (same ACPI id); it powers off by
  # signalling init on every power key press, bypassing logind
  boot.blacklistedKernelModules = [ "tiny_power_button" ];
  # NOTE 2026-10-22 eMudhra intermediate CA keys leaked (CVE-2026-111943);
  # non-browser TLS clients trust them via these roots -- drop once
  # nixpkgs' cacert no longer ships them
  security.pki.caCertificateBlacklist = [
    "emSign ECC Root CA - C3"
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign Root CA - G1"
  ];
  programs.iotop = {
    # setcap wrapper to use rootless
    enable = true;
  };
}
