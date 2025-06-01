{ config, inputs, ... }@args:
let
  user = config.user.username;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${user} = import ./hm.nix args;
  };
}
