{
  pkgs,
  cluster,
  config,
  ...
}:
{
  services.nextcloud = {
    enable = true;
    hostName = config.networking.hostName;
  };
}
