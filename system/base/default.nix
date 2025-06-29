# vim: fdl=0 fdm=marker
{
  lib,
  user,
  cluster,
  config,
  ...
}:
{
  imports = [
    ./builder.nix
    ./llm.nix
    ./nix.nix
    ./user.nix
    ./home.nix
    ./rice.nix
    ./net.nix
  ];

  # TODO move?
  time.timeZone = user.tz;
  i18n.defaultLocale = user.locale;

  # TODO doesn't work
  # need to expose GNUPGHOME for starters
  security.pam.services.login.gnupg = {
    enable = true;
    noAutostart = true;
  };
  security.pam.services.swaylock.gnupg = {
    enable = true;
    noAutostart = true;
  };

  boot.initrd.systemd.enable = true; # TODO idk why I have this

  # TODO check through virtualisation; also maybe we can move some of it
  virtualisation = {
    # common container config files in /etc/containers
    containers.enable = true;
    podman = {
      enable = true;
      # docker aliases
      dockerCompat = true;
      # > Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  hardware.nvidia-container-toolkit = {
    enable = config.hardware.nvidia.enabled;
    mount-nvidia-executables = true; # TODO ?
  };

  services.getty.autologinOnce = true; # autologin on boot on the first tty (it's encrypted anyway)
  hardware.enableAllFirmware = true; # as in "regardless of license"
  programs.iotop = {
    # setcap wrapper to use rootless
    enable = true;
  };
}
