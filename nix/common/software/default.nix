{ pkgs, dummy, ... }:
{
  imports = dummy ./.;

  environment.systemPackages = with pkgs; [
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
