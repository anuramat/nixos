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
    ./nix.nix
    ./user.nix
    ./home.nix
    ./net.nix
  ];

  security.rtkit.enable = true; # realtime kit, hands out realtime priority to user processes
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

  services = {
    ollama =
      let
        cuda = config.hardware.nvidia.enabled;
      in
      {
        enable = true;
        acceleration = lib.mkIf cuda "cuda";
        loadModels = lib.mkIf cuda [ ]; # pull models on service start
        environmentVariables = {
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KEEP_ALIVE = "999999m";
          OLLAMA_CONTEXT_LENGTH = "200000";
        };
        port = 11434; # explicit default
        host = "0.0.0.0";
        openFirewall = false; # disable to limit the interfaces
      };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    config.services.ollama.port
  ];
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
