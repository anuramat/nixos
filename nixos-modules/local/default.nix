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
    ./cuda.nix
    ./rocm.nix
    ./peripherals.nix
    ./remaps.nix
    ./rice.nix
  ];

  virtualisation = {
    containers.enable = true; # common container config files in /etc/containers
    podman = {
      enable = true;
      dockerCompat = true;
      # > Required for containers under podman-compose to be able to talk to each other.
      # TODO is this still needed?
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  services.getty.autologinOnce = true; # TODO only if full disk encryption

  programs.gpu-screen-recorder.enable = true; # NOTE doesn't install the package

  programs.steam.enable = true;

  security = {
    soteria.enable = true; # polkit auth agent
    rtkit.enable = true; # realtime kit, hands out realtime priority to user processes
    pam.services =
      let
        lockCfg = {
          nodelay = true;
          gnupg = {
            enable = true;
            noAutostart = true;
          };
        };
      in
      {
        swaylock-plugin = lockCfg;
        swaylock = lockCfg;
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
    # FUCK
    # BUG
    # doesn't do anything on lid close
    logind.settings.Login = {
      HandlePowerKey = "suspend";
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "suspend";
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
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
      jack.enable = true;
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

  # TODO move to local-minimal; the rest to local-heavy
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

  environment.systemPackages = with pkgs; [
    protonvpn-gui
  ];
}
