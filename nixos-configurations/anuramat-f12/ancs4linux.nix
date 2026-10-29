# iOS notifications; pair with `ancs4linux-ctl enable-advertising`
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs.self.consts.user) username;
  session = config.home-manager.users.${username}.wayland.systemd.target;
in
{
  environment.systemPackages = [ pkgs.ancs4linux ];
  services.dbus.packages = [ pkgs.ancs4linux ];
  # systemd.packages ignores [Install]
  systemd = {
    packages = [ pkgs.ancs4linux ];
    services.ancs4linux-advertising.wantedBy = [ "multi-user.target" ];
    services.ancs4linux-observer.wantedBy = [ "multi-user.target" ];
    # needs the notification server, which comes up with the session
    # but isn't D-Bus activatable, so it may not own its name yet
    user.services.ancs4linux-desktop-integration = {
      wantedBy = [ session ];
      partOf = [ session ];
      after = [ session ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
  # the dbus policies let this group talk to the daemons
  users.groups.ancs4linux = { };
  users.users.${username}.extraGroups = [ "ancs4linux" ];
}
