# vim: fdl=0 fdm=marker
{
  config,
  hax,
  inputs,
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
    ../user-config.nix

    inputs.agenix.nixosModules.default
    inputs.self.sharedModules.age
    inputs.nix-topology.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager =
    let
      username = config.userConfig.username;
    in
    {
      extraSpecialArgs = {
        inherit hax inputs;
      };
      users.${username} = {
        imports = with inputs.self.homeModules; [
          default
          linux
        ];
      };
    };

  i18n.defaultLocale = "en_US.UTF-8";
  hardware.enableAllFirmware = true; # as in "regardless of license"
  programs.iotop = {
    # setcap wrapper to use rootless
    enable = true;
  };

  boot.initrd.systemd.enable = true; # TODO idk why I have this
}
