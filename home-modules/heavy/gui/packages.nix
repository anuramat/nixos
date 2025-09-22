{
  pkgs,
  ...
}:
{
  # packages
  home.packages = with pkgs; [
    # unfiled
    qalculate-gtk # qalc calculator gui
    transmission_4-gtk # torrent client
    desktop-file-utils # update-desktop-database etc
    xdg-utils # xdg-open etc
    gtk3 # gtk-launch - starts an app by name of the desktop file
    dbeaver-bin # databases

    # documents
    gnumeric # spreadsheets
    kdePackages.okular # aio doc reader with pdf form support
    libreoffice # just in case
    pdfpc # pdf presentations, broken on wayland
    pympress # pdf presentations
    zathura # keyboard-centric pdf/djvu reader
    zotero

    # notes
    # xournalpp # pdf markup, handwritten notes # TODO takes a long time to rebuild when changing stylix theme
    logseq # whiteboard is kinda worth it?
    standardnotes # only notes BUT might get proton integration -- soon (tm)
    anytype

    # img
    # krita # raster graphics, digital art # XXX not in cache, takes ages to build
    inkscape-with-extensions # vector graphics
    gimp-with-plugins
    darktable
    rawtherapee

    # video
    mpv
    footage # simple editor: trim, crop, etc
    # davinci-resolve # heavy duty editor

    # comms
    element-desktop # matrix client
    # onionshare # tor-based file-sharing etc
    # onionshare-gui # p2p file sharing, chat, website hosting
    # qtox # p2p IM XXX broken
    # slack # XXX broken
    telegram-desktop

    # browsers
    tor-browser-bundle-bin
    google-chrome

    # terminals
    cool-retro-term
  ];
}
