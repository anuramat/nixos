{
  pkgs,
  ...
}:
{
  # packages
  home.packages = with pkgs; [
    # essentials
    wdisplays # GUI kanshi config generator
    libnotify # notify-send etc
    playerctl # cli media player controls
    mako # notifications - smaller than fnott and dunst
    waybar # status bar

    # config utils
    glib # gsettings (gtk etc)
    ddcutil # configure external monitors (eg brightness)

    # gui settings
    networkmanagerapplet # networking
    helvum # pipewire patchbay
    pavucontrol # audio
    system-config-printer # printer

    # screen capture etc
    slurp # select screen region
    swappy # screenshot markup
    shotman # screenshot, with simple preview afterwards, no markup
    wf-recorder # CLI screen capture
    hyprpicker # color picker
    satty # screenshot markup
    grim # barebones screenshot tool

    # unfiled
    qalculate-gtk # qalc calculator gui
    cheese # webcam
    proton-pass # password manager
    transmission_4-gtk # torrent client
    wev # wayland event viewer, useful for debugging
    chatterino2 # gui twitch chat client
    spotify
    steam
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

    # docs
    xournalpp # pdf markup, handwritten notes
    kdePackages.okular # aio doc reader with pdf form support
    zathura # keyboard-centric pdf/djvu reader
    gnumeric # spreadsheets
    # khoj # ai stuff
    libreoffice # just in case

    # img
    # krita # raster graphics, digital art # XXX not in cache, takes ages to build
    inkscape-with-extensions # vector graphics
    # mypaint # not-ms-paint # XXX broken
    swayimg # image viewer
    xfig # vector graphics, old as FUCK
    gimp-with-plugins # raster graphics
    darktable # lightroom
    rawtherapee # lightroom

    # video
    vlc
    mpv
    footage # simple editor: trim, crop, etc
    # davinci-resolve # heavy duty editor

    # theme
    # TODO apply
    dracula-icon-theme # for the bar

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
