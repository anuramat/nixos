# vim: fdl=0 fdm=marker
{
  lib,
  pkgs,
  unstable,
  config,
  dummy,
  ...
}:
let
  # nvidia = config.hardware.nvidia.enabled; # only in unstable
  nvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
in
{
  imports = dummy ./.;
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

  # external pkgs {{{1
  services.flatpak.enable = true;
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
    alsa-utils
    dbeaver-bin # databases
    mesa-demos # some 3d demos, useful for graphics debugging

    # docs {{{2
    xournalpp # pdf markup, handwritten notes
    okular # aio doc reader with pdf form support
    zathura # keyboard-centric pdf/djvu reader
    zotero # TODO remove after backing up
    libreoffice # just in case

    # img {{{2
    krita # raster graphics, digital art
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
    unstable.cheese # webcam
    proton-pass # password manager
    transmission_4-gtk # torrent client
    wev # wayland event viewer, useful for debugging

    # theme {{{2
    hackneyed # windows inspired cursor theme
    dracula-icon-theme # for the bar
    # }}}
  ];
  programs.seahorse.enable = true; # gnome keyring frontend

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

  # disks {{{1
  programs.gnome-disks.enable = true; # udisks2 frontend
  services.udisks2 = {
    enable = true;
    mountOnMedia = true;
  };

  # misc hacks {{{1
  # force native wayland support in chrome/electron apps; TODO check if still required
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
    # jupyter etc
    8000
    8080
    8888
  ];
}
