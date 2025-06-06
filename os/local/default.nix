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

  # external pkgs {{{1
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # captive portal support {{{1
  # TODO
  # programs.captive-browser = {
  #   enable = true;
  # };

  # packages {{{1
  environment.systemPackages = with pkgs; [
    # essentials {{{2
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
    alsa-utils
    dbeaver-bin # databases
    mesa-demos # some 3d demos, useful for graphics debugging

    # docs {{{2
    xournalpp # pdf markup, handwritten notes
    kdePackages.okular # aio doc reader with pdf form support
    zathura # keyboard-centric pdf/djvu reader
    gnumeric # spreadsheets
    libreoffice # just in case

    # img {{{2
    # krita # raster graphics, digital art # XXX not in cache, takes ages to build
    inkscape-with-extensions # vector graphics
    # mypaint # not-ms-paint # XXX broken
    swayimg # image viewer
    xfig # vector graphics, old as FUCK
    gimp-with-plugins # raster graphics
    darktable # lightroom
    rawtherapee # lightroom

    # video {{{2
    vlc
    mpv
    footage # simple editor: trim, crop, etc
    # davinci-resolve # heavy duty editor

    # misc system {{{2
    qalculate-gtk # qalc calculator gui
    cheese # webcam
    proton-pass # password manager
    transmission_4-gtk # torrent client
    wev # wayland event viewer, useful for debugging

    # theme {{{2
    hackneyed # windows inspired cursor theme
    dracula-icon-theme # for the bar
    # }}}
  ];

  services.protonmail-bridge = {
    enable = true;
  };

  # disks {{{1
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

  # bluetooth {{{1
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

  # boot {{{1
  # on desktops we expect efi
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      memtest86.enable = true;
      edk2-uefi-shell.enable = true;
      netbootxyz.enable = true;
    };
    efi.canTouchEfiVariables = true;
  };

  # firewall {{{1
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    # development, jupyter, etc
    8000
    8080
    8888
  ];
}
