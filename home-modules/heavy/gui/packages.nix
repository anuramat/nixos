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

    # docs
    xournalpp # pdf markup, handwritten notes
    kdePackages.okular # aio doc reader with pdf form support
    pympress # pdf presentation
    pdfpc # pdf presentation, broken on wayland
    zathura # keyboard-centric pdf/djvu reader
    gnumeric # spreadsheets
    logseq
    obsidian
    libreoffice # just in case
    saber
    joplin-desktop
    standardnotes
    zotero

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
