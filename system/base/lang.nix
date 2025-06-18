{
  pkgs,
  old,
  ...
}:
{
  # TODO move as much as possible to home-manager (make sure not to break the system)
  environment.systemPackages = with pkgs; [

  ];
}
# vim: fdm=marker fdl=0
