{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./external_keys.nix
    ./home.nix
    ./hosts.nix
    ./net.nix
    ./nix.nix
    ./user.nix
    ./web.nix

    inputs.agenix.nixosModules.default
    inputs.self.sharedModules.age
    inputs.self.sharedModules.nixpkgs
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };
    users.${inputs.self.user.username} = {
      imports = with inputs.self.homeModules; [
        default
        linux
      ];
      home.stateVersion = lib.mkDefault config.system.stateVersion;
    };
  };

  i18n.defaultLocale = inputs.self.user.locale;
  time.timeZone = inputs.self.user.timeZone;
  hardware = {
    enableAllFirmware = true; # as in "regardless of license"; implies redistributable
    enableAllHardware = true;
  };
  programs.iotop = {
    # setcap wrapper to use rootless
    enable = true;
  };

  boot.initrd.systemd.enable = true; # TODO idk why I have this
}
