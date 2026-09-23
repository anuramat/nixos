{
  pkgs,
  ...
}:
{
  # packages; cross-platform ones live in heavy/gui.nix
  home.packages = with pkgs; [
    # desktop plumbing
    desktop-file-utils # update-desktop-database etc
    xdg-utils # xdg-open etc
    gtk3 # gtk-launch - starts an app by name of the desktop file

    # documents
    kdePackages.okular # aio doc reader with pdf form support
    libreoffice # just in case

    # notes
    standardnotes # only notes BUT might get proton integration -- soon (tm)

    # img
    gimp-with-plugins
    rawtherapee

    # video
    footage # simple editor: trim, crop, etc
    # davinci-resolve # heavy duty editor

    # comms
    # onionshare # tor-based file-sharing etc
    # onionshare-gui # p2p file sharing, chat, website hosting
    # qtox # p2p IM XXX broken
    # slack # XXX broken

    # browsers
    tor-browser
  ];
}
