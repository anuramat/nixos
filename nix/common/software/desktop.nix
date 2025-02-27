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
    avizo # brightness/volume control with overlay indicator
    grim # barebones screenshot tool
    kanshi # display config daemon
    wdisplays # GUI kanshi config generator
    libnotify # notify-send etc
    mako # notifications - smaller than fnott and dunst
    networkmanagerapplet # networking
    slurp # select screen region
    swappy # screenshot markup
    satty # screenshot markup
    swaybg # wallpaper
    swayidle # lock/sleep on idle
    swaylock # lockscreen
    udiskie # udisk2 applet frontend
    waybar # status bar
    waypipe # gui forwarding
    wl-clip-persist # otherwise clipboard contents disappear on exit
    wl-clipboard # wl-copy/wl-paste: copy from stdin/paste to stdout
    wl-mirror # screen mirroring

    glib # gsettings (gtk etc)
    hackneyed # windows inspired cursor theme
    dracula-icon-theme # for the bar
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
  # force native wayland support in chrome/electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        unstable.xdg-desktop-portal-termfilechooser # not in stable yet
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
        default = "foot.desktop";
      };
    };
  };
}
