{
  config,
  inputs,
  ...
}:
{
  home-manager = {
    backupFileExtension = "HMBAK";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
  };
  environment.pathsToLink = [
    # required because of useUserPackages and xdg.portal
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];
}
