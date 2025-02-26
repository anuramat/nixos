# vim: fdl=0 fdm=marker
{
  pkgs,
  unstable,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Browsers {{{1
    inputs.zen-browser.packages.${pkgs.system}.specific
    tor-browser-bundle-bin
    firefox
    google-chrome

    # Terminals {{{1
    cool-retro-term
    foot
    unstable.ghostty
    wezterm

    # Settings {{{1
    ddcutil # configure external monitors (eg brightness)
    helvum # pipewire patchbay
    pavucontrol # gui audio configuration
    system-config-printer # printer gui

    # Opening stuff {{{1
    desktop-file-utils # update-desktop-database etc
    wmenu # dmenu 1to1
    bemenu # slightly better
    j4-dmenu-desktop # .desktop wrapper for dmenus
    xdg-utils # xdg-open etc
    gtk3 # gtk-launch - starts an app by name of the desktop file
    xdragon # drag and drop from terminal

    # Terminal helpers {{{1
    playerctl # cli media player controls

    # Wallpaper helpers {{{1
    glpaper # shader
    mpvpaper # video

    # Screenshots and screen capture {{{1
    kooha # screen capture with basic gui
    shotman # screenshot, with simple preview afterwards, no markup
    wf-recorder # CLI screen capture

    # Comms {{{1
    element-desktop # matrix client
    onionshare # tor-based file-sharing etc
    onionshare-gui # p2p file sharing, chat, website hosting
    # qtox # p2p IM # XXX broken
    # slack # XXX broken
    telegram-desktop
    whatsapp-for-linux # isn't this worthless TODO

    # Misc {{{1
    hyprpicker # simple terminal color picker
    chatterino2 # gui twitch chat client
    qalculate-gtk # qalc calculator gui
    spotify
    steam
    cheese # webcam
    proton-pass
    transmission_4-gtk # transmission torrent client gui
    # better pywal TODO go back to stable when xdg compialnt version gets released
    # unstable.wallust
    inputs.wallust.packages.${pkgs.system}.default
    wev # wayland event viewer, useful for debugging
    # }}}
  ];

  programs.obs-studio = {
    enable = true;
    plugins = with unstable.obs-studio-plugins; [
      obs-backgroundremoval
      obs-gstreamer
      obs-multi-rtmp # multi-site
      obs-nvfbc
      obs-pipewire-audio-capture
      obs-tuna # song info
      obs-vaapi
      wlrobs # screen capture for wlroots
    ];
  };
}
