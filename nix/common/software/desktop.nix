# https://nixos.wiki/wiki/Sway
# contents: most of the DE-ish stuff
{ pkgs, unstable, ... }:
{
  programs = {
    sway = {
      enable = true;
      # TODO doc this
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        dbus # make sure dbus-update-activation-environment is available
        # isnt dbus already in there anyway?
      ];
    };

    # captive-browser = {
    #   enable = true;
    # };
  };

  # packages {{{1
  environment.systemPackages = with pkgs; [
    # Essentials {{{2
    avizo # brightness/volume control with overlay indicator
    kanshi # display config daemon
    wdisplays # GUI kanshi config generator
    libnotify # notify-send etc
    playerctl # cli media player controls
    mako # notifications - smaller than fnott and dunst
    waybar # status bar

    # Browsers {{{2
    inputs.zen-browser.packages.${pkgs.system}.specific
    tor-browser-bundle-bin
    firefox
    google-chrome

    # Terminals {{{2
    cool-retro-term
    foot
    unstable.ghostty
    wezterm

    # Config utils {{{2
    glib # gsettings (gtk etc)
    ddcutil # configure external monitors (eg brightness)

    # Gui settings {{{2
    networkmanagerapplet # networking
    helvum # pipewire patchbay
    pavucontrol # audio
    system-config-printer # printer

    # Screen capture etc {{{2
    slurp # select screen region
    swappy # screenshot markup
    kooha # screen capture with basic gui
    shotman # screenshot, with simple preview afterwards, no markup
    wf-recorder # CLI screen capture
    hyprpicker # color picker
    satty # screenshot markup
    grim # barebones screenshot tool

    # Wallpaper helpers {{{2
    swaybg # image
    mpvpaper # video
    glpaper # shader

    # Unfiled {{{2
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

    # Misc {{{2
    qalculate-gtk # qalc calculator gui
    cheese # webcam
    proton-pass # password manager
    transmission_4-gtk # torrent client
    # unstable.wallust # better pywal TODO go back to stable when xdg compliant version gets merged
    inputs.wallust.packages.${pkgs.system}.default
    wev # wayland event viewer, useful for debugging

    # Theme {{{2
    hackneyed # windows inspired cursor theme
    dracula-icon-theme # for the bar
    # }}}
  ];

  # external pkgs {{{1
  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

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
}
