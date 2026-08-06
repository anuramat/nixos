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
    zotero

    # notes
    xournalpp # pdf markup, handwritten notes
    rnote
    standardnotes # only notes BUT might get proton integration -- soon (tm)

    # img
    gimp-with-plugins
    darktable
    rawtherapee

    # video
    footage # simple editor: trim, crop, etc
    # davinci-resolve # heavy duty editor

    # comms
    element-desktop # matrix client
    # onionshare # tor-based file-sharing etc
    # onionshare-gui # p2p file sharing, chat, website hosting
    # qtox # p2p IM XXX broken
    # slack # XXX broken
    telegram-desktop
    discord

    # browsers
    tor-browser
    google-chrome

    # terminals
    cool-retro-term
  ];
}
