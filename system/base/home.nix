{
  config,
  user,
  inputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  hardware.graphics.enable = true;
  home-manager = {
    backupFileExtension = "HMBAK";
    useGlobalPkgs = true;
    useUserPackages = true;
    # extraSpecialArgs = {
    #   inherit user;
    # };
  };
  environment.pathsToLink = [
    # required because of useUserPackages and xdg.portal
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];
}
