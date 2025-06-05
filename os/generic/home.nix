{ config, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  stylix.homeManagerIntegration.followSystem = true;
  hardware.graphics.enable = true;
  home-manager = {
    backupFileExtension = "HMBAK";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.user.username} = import ./home;
  };
  environment.pathsToLink = [
    # required because of useUserPackages and xdg.portal
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];
}
