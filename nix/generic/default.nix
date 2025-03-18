# vim: fdl=0 fdm=marker
{
  lib,
  cluster,
  dummy,
  config,
  ...
}:
let
  # nvidia = config.hardware.nvidia.enabled; # only in unstable
  nvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
in
{
  imports = dummy ./.;
  hardware.enableAllFirmware = true; # as in "regardless of license"
  services.gnome.gnome-keyring.enable = true; # security credential storage, exposed over dbus

  # virtualization {{{1
  virtualisation = {
    virtualbox = {
      host = {
        enable = true;
      };
      guest = {
        enable = true;
      };
    };
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
    enable = nvidia;
    mount-nvidia-executables = true;
  };

  # boot and tty {{{1
  # TODO remove values that mirror defaults
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        memtest86.enable = true;
        edk2-uefi-shell.enable = true;
        netbootxyz.enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
    # silent boot, suggested by boot.initrd.verbose description:
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      systemd.enable = true;
    };
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
    plymouth.enable = true;
  };
  # autologin, tty prompt
  services.getty = {
    greetingLine = ''\l'';
    helpLine = "";
    autologinOnce = true;
  };

  # networking {{{1
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        8080
        8888
        5000 # nix-serve
      ];
      allowedUDPPorts = [ ];
    };
    networkmanager = {
      enable = true;
    };
  };
  # breaks rebuilds sometimes: <https://github.com/NixOS/nixpkgs/issues/180175>
  systemd.services.NetworkManager-wait-online.enable = false;

  # ssh etc {{{1
  programs.ssh.knownHostsFiles = cluster.hostKeysFiles;
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
  # }}}
}
