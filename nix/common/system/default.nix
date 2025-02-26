{
  unstable,
  dummy,
  cluster,
  lib,
  ...
}:
{
  imports = dummy ./.;
  hardware.enableAllFirmware = true; # as in "regardless of license"
  programs.ssh.knownHostsFiles = cluster.hostKeysFiles;

  programs.adb.enable = true; # android stuff
  security.rtkit.enable = true; # realtime kit, hands out realtime priority to user processes
  services.tcsd.enable = true; # might fix long sysinit-reactivation.target restart times

  # fonts {{{1
  fonts = {
    packages = with unstable; [
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Hack Nerd Font" ];
      };
    };
  };

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

  # boot {{{1
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
    plymouth = {
      theme = "breeze"; # package is overridden to use a nixos logo
      enable = true;
    };
  };
  # autologin, tty prompt
  services.getty = {
    greetingLine = ''\l'';
    helpLine = "";
    autologinOnce = true;
  };

  # power {{{1
  # TODO check if it's a laptop
  services.logind.extraConfig = ''
    HandlePowerKey=hybrid-sleep
    HandlePowerKeyLongPress=ignore
    HandleSuspendKey=suspend
    HandleHibernateKey=suspend
    HandleLidSwitch=suspend
    HandleLidSwitchDocked=ignore
    HandleLidSwitchExternalPower=ignore
  '';
  services = {
    thermald.enable = true; # cooling
    tlp = {
      # voltage, wifi/bluetooth cli switches
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = lib.mkDefault 30;
      };
    };
    upower.enable = true; # suspend on low battery
  };

  # bluetooth {{{1
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true; # bluetooth gui

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
