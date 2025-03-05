{
  pkgs,
  unstable,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # comms {{{1
    element-desktop # matrix client
    onionshare # tor-based file-sharing etc
    onionshare-gui # p2p file sharing, chat, website hosting
    # qtox # p2p IM XXX broken
    # slack # XXX broken
    telegram-desktop
    whatsapp-for-linux

    # browsers {{{1
    inputs.zen-browser.packages.${pkgs.system}.specific
    tor-browser-bundle-bin
    firefox
    librewolf
    google-chrome

    # terminals {{{1
    cool-retro-term
    foot
    unstable.ghostty
    wezterm

    # misc {{{1
    chatterino2 # gui twitch chat client
    spotify
    steam
  ];

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-gstreamer
      obs-multi-rtmp # multi-site
      obs-nvfbc
      obs-pipewire-audio-capture
      obs-tuna # song info
      obs-vaapi
      wlrobs # screen capture for wlroots
    ];
    enableVirtualCamera = true; # set up the v4l2loopback kernel module
  };
  programs.gphoto2.enable = true; # dslr interface

  services.ollama = {
    enable = true;
    acceleration = "cuda";
    # pull models on service start
    loadModels = [ ];
  };
}
