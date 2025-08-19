# vim: fdl=0 fdm=marker
{
  lib,
  inputs,
  username,
  hax,
  ...
}:
{
  imports = [
    ./llama.nix
    ./peripherals.nix
    ./remaps.nix
    ./rice.nix
    inputs.musnix.nixosModules.musnix
  ];

  home-manager = {
    users.${username} = {
      imports = with inputs.self.homeModules; [
        heavy
      ];
    };
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  hardware.graphics.enable = true;

  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
      };
      pulse.enable = true;
      wireplumber = {
        enable = true;
      };
      # TODO mess with musnix and jack later, try out monitoring
      # jack = {
      #   enable = true;
      # };
    };
  };

  # musnix = {
  #   enable = true;
  # };

  programs.captive-browser = {
    enable = true;
  };

  programs.gphoto2.enable = true; # dslr interface
  programs.obs-studio.enableVirtualCamera = true; # set up the v4l2loopback kernel module, used in home-manager
  services.protonmail-bridge = {
    enable = true;
  };

  programs.gnome-disks.enable = true; # udisks2 frontend
  services.udisks2 = {
    enable = true;
    mountOnMedia = true;
  };

  # print/scan {{{1
  # TODO move this to notes?
  # scanning - `scanimage`
  # printing - CUPS @ http://localhost:631/ or a desktop entry cups.desktop (Manage Printing)
  # printer settings and job list - `system-config-printer`
  # list printers - `lpstat -p`
  # list printer jobs - `lpstat`
  # cancel job - `cancel 1`
  services = {
    # Enable CUPS to print documents, available @ http://localhost:631/
    printing = {
      enable = true;
      drivers = [ ]; # some printers need additional drivers
    };
    # Implementation for Multicast DNS aka Zeroconf aka Apple Rendezvous aka Apple Bonjour
    # which is responsible for network printers autodiscovery (not only that)
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true; # Open udp 5353 for network devices discovery
    };
  };
  hardware.printers = { }; # some printers need additional configuration
  hardware.sane = {
    enable = true;
    extraBackends = [ ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true; # bluetooth gui

  # power {{{1
  # HandlePowerKeyLongPress=ignore
  services.logind.extraConfig = ''
    HandlePowerKey=suspend
    HandleSuspendKey=suspend
    HandleHibernateKey=suspend
    HandleLidSwitch=ignore
    HandleLidSwitchDocked=ignore
    HandleLidSwitchExternalPower=ignore
  '';
  services = {
    thermald.enable = true; # cooling
    tlp = {
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
    upower = {
      enable = true; # sleep on low battery
      usePercentageForPolicy = true;
      percentageCritical = 10;
      criticalPowerAction = "Hibernate";
    };
  };

  boot.loader = {
    # on desktops we expect efi
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      memtest86.enable = true;
      edk2-uefi-shell.enable = true;
      netbootxyz.enable = true;
    };
    efi.canTouchEfiVariables = true;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    # development, jupyter, etc
    8000
    8080
    8888
  ];
}
