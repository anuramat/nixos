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
  ];

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

  hardware.enableAllFirmware = true; # as in "regardless of license"

  # TODO why is this here and not home manager? remove the package also
  programs.iotop = {
    enable = true;
  };

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

  # TODO remove values that mirror defaults
  boot = {
    # silent boot, taken from boot.initrd.verbose description:
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      systemd.enable = true; # TODO idk why I have this
    };
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
    plymouth.enable = true; # rice
  };
  # autologin, tty prompt
  # TODO check if this is the cleanest setup
  services.getty = {
    greetingLine = ''\l'';
    helpLine = "";
    autologinOnce = true;
  };

  networking = {
    firewall = {
      enable = true;
    };
    networkmanager = {
      enable = true;
    };
  };

  services.resolved = {
    enable = true;
    # dnssec = "true"; # TODO breaks sometimes, try again with captive
  };

  programs.ssh = {
    knownHostsFiles = cluster.hostKeysFiles;
    extraConfig =
      let
        prefix = user.username + "-";
        mkAliasEntry =
          hostname: # ssh_config
          ''
            Host ${lib.strings.removePrefix prefix hostname}
              HostName ${hostname}
          '';
      in
      cluster.hostnames
      |> lib.filter (x: lib.strings.hasPrefix prefix x)
      |> map mkAliasEntry
      |> lib.strings.intersperse "\n"
      |> lib.concatStrings;
  };
  services = {
    fail2ban.enable = true; # intrusion prevention
    tailscale.enable = true;
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PrintLastLog = false;
      };
    };
  };
}
