# notifies the user wherever they are: shown on this host, then routed by
# notify-forward to an unlocked peer or the phone
{
  config,
  lib,
  osConfig ? null,
  ...
}:
{
  config = lib.mkIf (osConfig != null) {
    home.packages = [ (config.lib.ntfy.send "notify" "desktop-${osConfig.networking.hostName}") ];
  };
}
