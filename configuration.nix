# > man 5 configuration.nix
# > nixos help

{ config, pkgs, lib, ... }:

let
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sway boilerplate ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # https://nixos.wiki/wiki/Sway
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };
  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        gsettings set $gnome_schema gtk-theme 'Dracula'
        gsettings set $gnome_schema icon-theme 'Dracula'
        gsettings set $gnome_schema color-scheme 'prefer-dark'
      '';
  };

  # 37M download on each rebuild
  unstableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  networking.hostName = "anuramat-t480"; # Define your hostname.

  time.timeZone = "Etc/GMT-6"; # WARN inverted
  i18n.defaultLocale = "en_US.UTF-8";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Enable CUPS to print documents.
  services.printing.enable = true;
  # some more boilerplate from wiki https://nixos.wiki/wiki/Printing
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  # for a WiFi printer
  services.avahi.openFirewall = true;


  # TODO uncomment
  services.thermald.enable = true; # cooling control
  services.tlp.enable = true; # power management, wifi/bluetooth cli switches

  hardware.bluetooth =
    {
      enable = true;
      powerOnBoot = true;
    };

  services.blueman.enable = true; # bluetooth

  services.logind.extraConfig = ''
    HandlePowerKey=hybrid-sleep
    HandlePowerKeyLongPress=ignore
    HandleSuspendKey=suspend
    HandleHibernateKey=suspend
    HandleLidSwitch=suspend
    HandleLidSwitchDocked=ignore
    HandleLidSwitchExternalPower=ignore
  '';
  programs.light.enable = true;
  users.users.anuramat = {
    description = "Arsen Nuramatov";
    isNormalUser = true;
    extraGroups = [
      "wheel" # root
      "video" # screen brightess
      "network" # wifi
      "docker" # docker
      "audio" # just in case
    ];
    packages = with pkgs; [
      unstable.eza
      unstable.nixd
      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      qrcp # send files to mobile over Wi-Fi using QR
      exercism # CLI for exercism.org
      ripgrep-all # grep over pdfs etc
      zoxide # better cd
      difftastic # syntax aware diffs
      # ~~~~~~~~~~~~~~~~~~~~~~ File managers ~~~~~~~~~~~~~~~~~~~~~~~
      # TODO choose one?
      ranger
      nnn
      broot
      xplr
      # ~~~~~~~~~~~~~~~~~~~~~~~~ Languages ~~~~~~~~~~~~~~~~~~~~~~~~~
      nodejs_20
      yarn
      ruby
      perl
      # ~~~~~~~~~~~~~~~~~~~~~ Language support ~~~~~~~~~~~~~~~~~~~~~
      micromamba # conda rewrite in C++
      gopls # Go LSP
      bats # Bash testing
      nodePackages_latest.bash-language-server
      yamlfmt # YAML formatter
      bear # Compilation database generator for clangd
      black # Python formatter
      delve # Go debugger
      gofumpt # strict go formatter
      golangci-lint # gigalinter for go
      pyright # Python LSP
      shellcheck # *sh linter
      shfmt # posix/bash/mksh formatter
      stylua # Lua formatter
      lua-language-server
      luajitPackages.luacheck
      luajitPackages.luarocks
      marksman # markdown LSP
      # ~~~~~~~~~~~~~~~~~~~~~~~~ Disk usage ~~~~~~~~~~~~~~~~~~~~~~~~
      duf # disk usage (better "df")
      du-dust # directory disk usage (better du)
      ncdu # directory sidk usage (better du)
      # ~~~~~~~~~~~~~~~~~~~~~~~ Swiss tools ~~~~~~~~~~~~~~~~~~~~~~~~
      ffmpeg # video
      pandoc # markup (latex, markdown, etc)
      sox # audio
      imagemagickBig # images NOTE I don't know what "Big" means, might as well just use "imagemagick"
      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      git-filter-repo # rewrite/analyze repository history
      grpcui # postman for grpc
      grpcurl # curl for grpc
      htop # better top
      atop # even better top
      ctop # container top
      httpie # better curl
      kubectx
      kubectl
      emacs-gtk
      lazydocker
      lazygit
      llvm
      netcat
      nmap
      glow # markdown viewer
      nvi # vi clone
      parallel
      peco # interactive filtering
      prettyping # better "ping"
      tmux
      tree # not really needed, use "exa --tree" instead
      universal-ctags
      youtube-dl
      nodePackages_latest.yaml-language-server
      taskwarrior # TODO todos
      ghq # git repository manager
      gh # GitHub CLI
      lsix # ls for images (sixel)
      nvtop # top for GPUs
      wtf # dashboard
      libqalculate # qalc - advanced calculator
      aria # downloader
      hyprpicker # gigasimple terminal color picker
      neofetch
      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GUI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # file managers
      cinnamon.nemo
      # libsForQt5.dolphin
      # xfce.thunar
      # gnome.nautilus
      # ---------------

      # davinci-resolve
      flameshot # screenshot + markup
      swappy # screenshot + markup, more terminal friendly
      qalculate-gtk # gui for qalc
      gimp-with-plugins
      kitty
      alacritty
      foot
      telegram-desktop
      element-desktop
      syncthing
      discord
      discordo
      djview
      djvulibre
      apvlv # vi-like pdf/epub viewer
      vlc
      transmission
      transmission-gtk
      spotify
      tor-browser-bundle-bin
      slack
      gnome.pomodoro
      solanum # yet another pomodoro
      sageWithDoc
      onionshare
      onionshare-gui
      obsidian
      obs-studio
      cheese # webcam
      # haskellPackages.ghcup # broken as of 2023-09-05
    ];
  };

  virtualisation.docker = {
    enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.package = pkgs.nixUnstable;
  fonts.fonts = with pkgs; [
    nerdfonts
  ];

  # TODO CHECK
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = false;
    viAlias = false;
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };


  # https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    # TODO some of these aren't needed probably
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  # "sound.enable is only meant for ALSA-based configurations"
  sound.enable = false;
  # "optional but recommended"
  security.rtkit.enable = true;

  # services.dbus.enable = true; # TODO is this needed explicitly? try pruning?

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # keyboard
  services.xserver = {
    layout = "us,ru";
    xkbOptions = "ctrl:swapcaps,altwin:swap_lalt_lwin,grp:alt_shift_toggle";
  };

  environment.systemPackages = with pkgs; [
    # Basics
    bash
    killall
    clang
    coreutils-full # just in case
    curl
    gcc
    git
    gnumake
    go
    less
    lsof
    python3
    wget
    wirelesstools # iw*
    zip
    unzip
    progress # progress status for cp etc
    efibootmgr
    # CLI
    bash-completion
    nix-bash-completions
    nixpkgs-fmt # nix formatter
    bat # better cat with syntax hl
    croc # send/receive files
    delta # better diffs
    exa # better ls
    fd # find alternative
    fzf # fuzzy finder
    ripgrep # better grep
    # GUI
    chromium
    firefox
    okular # document viewer
    # Desktop environment
    i3status # status line generator
    wev # wayland event viewer
    grim # screenshot
    slurp # select area for screenshot
    mako # notifications
    xdg-utils # for opening default programs when clicking links
    wdisplays # gui display configuration
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wayland # TODO check if this is directly required
    imv

    nwg-bar
    nwg-menu
    nwg-dock
    nwg-panel
    nwg-drawer
    nwg-wrapper
    nwg-launchers

    swayidle # idle events
    swaylock # lockscreen
    bemenu # wayland clone of dmenu
    glib # gsettings (gtk etc)
    pavucontrol # gui audio configuration
    networkmanagerapplet
    # gtk themes, stored in /run/current-system/sw/share/themes
    dracula-theme
    dracula-icon-theme
    # unchecked TODO
    dbus-sway-environment
    configure-gtk
  ];

  services.upower = {
    enable = true;
  };

  # networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # backup the configuration.nix to /run/current-system/configuration.nix
  system.copySystemConfiguration = true;

  # determines default settings for stateful data
  system.stateVersion = "23.05"; # WARN: DON'T TOUCH
}
