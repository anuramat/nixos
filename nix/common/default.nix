# vim: fdl=0 fdm=marker
{
  lib,
  pkgs,
  unstable,
  cluster,
  dummy,
  ...
}:
{
  imports = dummy ./.;
  hardware.enableAllFirmware = true; # as in "regardless of license"
  programs.adb.enable = true; # android stuff
  security.rtkit.enable = true; # realtime kit, hands out realtime priority to user processes

  # wm {{{1
  programs.sway = {
    enable = true;
    # TODO doc this; why is this not on by default
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      dbus # make sure dbus-update-activation-environment is available
      # isnt dbus already in there anyway?
    ];
  };

  # captive portal support {{{1
  programs.captive-browser = {
    enable = true;
  };

  # packages {{{1
  environment.systemPackages = with pkgs; [
    # essentials {{{2
    avizo # brightness/volume control with overlay indicator
    kanshi # display config daemon
    wdisplays # GUI kanshi config generator
    libnotify # notify-send etc
    playerctl # cli media player controls
    mako # notifications - smaller than fnott and dunst
    waybar # status bar

    # config utils {{{2
    glib # gsettings (gtk etc)
    ddcutil # configure external monitors (eg brightness)

    # gui settings {{{2
    networkmanagerapplet # networking
    helvum # pipewire patchbay
    pavucontrol # audio
    system-config-printer # printer

    # screen capture etc {{{2
    slurp # select screen region
    swappy # screenshot markup
    kooha # screen capture with basic gui
    shotman # screenshot, with simple preview afterwards, no markup
    wf-recorder # CLI screen capture
    hyprpicker # color picker
    satty # screenshot markup
    grim # barebones screenshot tool

    # wallpaper helpers {{{2
    swaybg # image
    mpvpaper # video
    glpaper # shader

    # unfiled {{{2
    swayidle # lock/sleep on idle
    swaylock # lockscreen
    udiskie # udisk2 applet frontend
    waypipe # gui forwarding
    wl-clip-persist # otherwise clipboard contents disappear on exit
    wl-clipboard # wl-copy/wl-paste: copy from stdin/paste to stdout
    wl-mirror # screen mirroring
    desktop-file-utils # update-desktop-database etc
    wmenu # dmenu 1to1
    bemenu # slightly better -- has dynamic height
    j4-dmenu-desktop # .desktop wrapper for dmenus
    xdg-utils # xdg-open etc
    gtk3 # gtk-launch - starts an app by name of the desktop file
    xdragon # terminal drag and drop

    # misc system {{{2
    qalculate-gtk # qalc calculator gui
    cheese # webcam
    proton-pass # password manager
    transmission_4-gtk # torrent client
    # unstable.wallust # better pywal TODO go back to stable when xdg compliant version gets merged
    inputs.wallust.packages.${pkgs.system}.default
    wev # wayland event viewer, useful for debugging

    # theme {{{2
    hackneyed # windows inspired cursor theme
    dracula-icon-theme # for the bar
    # }}}
  ];

  # creds {{{1
  services.gnome.gnome-keyring.enable = true; # security credential storage, exposed over dbus
  programs.seahorse.enable = true; # gnome keyring frontend

  # disks {{{1
  programs.gnome-disks.enable = true; # udisks2 frontend
  services.udisks2 = {
    enable = true;
    mountOnMedia = true;
  };

  # misc hacks {{{1
  # force native wayland support in chrome/electron apps; TODO check if still required
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # xdg {{{1
  xdg = {
    portal = {
      enable = true;
      wlr.enable = true; # screen capture
      extraPortals = [
        unstable.xdg-desktop-portal-termfilechooser # file picker; not in stable yet
        pkgs.xdg-desktop-portal-gtk # the rest: <https://wiki.archlinux.org/title/XDG_Desktop_Portal>
      ];
      config =
        let
          portalConfig = {
            "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
          };
        in
        {
          sway = portalConfig;
        };
    };
    terminal-exec = {
      enable = true;
      settings = {
        default = [ "foot.desktop" ];
      };
    };
  };

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

  # external pkgs {{{1
  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
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
