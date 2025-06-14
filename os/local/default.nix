# vim: fdl=0 fdm=marker
{
  config,
  lib,
  pkgs,
  cluster,
  ...
}:
{
  imports = [
    ./misc.nix
    ./peripherals.nix
    ./remaps.nix
  ];
  security.rtkit.enable = true; # realtime kit, hands out realtime priority to user processes
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
    };
  };

  programs.captive-browser = {
    enable = true;
  };

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
  services.logind.extraConfig = ''
    HandlePowerKey=hybrid-sleep
    HandlePowerKeyLongPress=ignore
    HandleSuspendKey=suspend
    HandleHibernateKey=suspend
  '';
  # HandleLidSwitch=suspend
  # HandleLidSwitchDocked=ignore
  # HandleLidSwitchExternalPower=ignore
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
    upower.enable = true; # suspend on low battery
  };

  # fonts {{{1
  fonts = {
    packages = with pkgs; [
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
