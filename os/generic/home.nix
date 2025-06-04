{ config, ... }:
{
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
