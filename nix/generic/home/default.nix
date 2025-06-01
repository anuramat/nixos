v:

let
  user = v.config.user.username;
in
{
  imports = [
    v.inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${user} = import ./hm.nix;
  };
}
