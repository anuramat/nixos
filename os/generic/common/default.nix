# vim: fdl=0 fdm=marker
{
  lib,
  pkgs,
  user,
  cluster,
  config,
  ...
}:
{
  imports = [
    ./builder.nix
    ./cli.nix
    ./lang.nix
    ./llm.nix
    ./nix.nix
    ./user.nix
  ];
  hardware.enableAllFirmware = true; # as in "regardless of license"

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
    enable = config.hardware.nvidia.enabled;
    mount-nvidia-executables = true;
  };

  # boot and tty {{{1
  # TODO remove values that mirror defaults
  boot = {
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
    };
    networkmanager = {
      enable = true;
    };
  };

  # BUG breaks rebuilds sometimes: <https://github.com/NixOS/nixpkgs/issues/180175>
  # HACK:
  systemd.services.NetworkManager-wait-online.enable = false;

  services.resolved = {
    enable = true;
    # dnssec = "true";
  };

  # ssh etc {{{1
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
  # }}}
}
