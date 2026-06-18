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
    ./llama.nix

    inputs.agenix.nixosModules.default
    inputs.self.sharedModules.age
    inputs.self.sharedModules.nixpkgs
    inputs.nix-topology.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager =
    let
      username = config.userConfig.username;
    in
    {
      extraSpecialArgs = {
        inherit inputs;
      };
      users.${username} = {
        imports = with inputs.self.homeModules; [
          default
          linux
        ];
        home.stateVersion = lib.mkDefault config.system.stateVersion;
      };
    };

  i18n.defaultLocale = "en_US.UTF-8";
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
