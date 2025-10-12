# TODO tidy comments
{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
  username = config.userConfig.username;
in
{
  imports = [
    ./peripherals.nix
    ./remaps.nix
    ./rice.nix
  ];

  services.getty.autologinOnce = true; # TODO only if full disk encryption

  security = {
    soteria.enable = true; # polkit auth agent
    rtkit.enable = true; # realtime kit, hands out realtime priority to user processes
    pam.services.swaylock.gnupg = {
      # TODO condition on home-manager swaylock
      enable = true;
      noAutostart = true;
    };
  };

  home-manager = {
    users.${username} = {
      imports = with inputs.self.homeModules; [
        heavy
        heavy-linux
      ];
    };
  };

  programs = {
    captive-browser.enable = true;
    gphoto2.enable = true; # dslr interface
    obs-studio.enableVirtualCamera = true; # set up the v4l2loopback kernel module, used in home-manager
    gnome-disks.enable = true; # udisks2 frontend
    appimage = {
      enable = true;
      binfmt = true;
    };
    nix-ld = {
      enable = true;
      libraries =
        let
          cudaLibs =
            if (config.nixpkgs.config.cudaSupport or false) then
              [
                config.hardware.nvidia.package
                pkgs.cudaPackages.cudatoolkit
              ]
            else
              [ ];
        in
        with pkgs;
        [
          icu
          gmp
          glibc
          openssl
          # TODO what is the difference?
          stdenv.cc.cc
          stdenv.cc.cc.lib
        ]
        ++ cudaLibs;
    };
  };

  environment.etc."udisks2/mount_options.conf" = {
    text = ''
      [defaults]
      btrfs_defaults=compress=zstd
    '';
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
    # power:
    # HandlePowerKeyLongPress=ignore
    logind.extraConfig = ''
      HandlePowerKey=suspend
      HandleSuspendKey=suspend
      HandleHibernateKey=suspend
      HandleLidSwitch=ignore
      HandleLidSwitchDocked=ignore
      HandleLidSwitchExternalPower=ignore
    '';
    thermald.enable = true; # cooling
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_MIN_PERF_ON_AC = mkDefault 50;
        CPU_MAX_PERF_ON_AC = mkDefault 100;
        CPU_MIN_PERF_ON_BAT = mkDefault 0;
        CPU_MAX_PERF_ON_BAT = mkDefault 30;
      };
    };
    upower = {
      enable = true; # sleep on low battery
      usePercentageForPolicy = true;
      percentageCritical = 10;
      criticalPowerAction = "Hibernate";
    };
    udisks2 = {
      enable = true;
      mountOnMedia = true;
    };
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
    blueman.enable = true; # bluetooth gui
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
  hardware = {
    graphics.enable = true;
    printers = { }; # some printers need additional configuration
    sane = {
      enable = true;
      extraBackends = [ ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = false;
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
