{
  pkgs,
  ...
}:
{
  # TODO move the file contents
  environment.systemPackages = with pkgs; [
  ];

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # obs-backgroundremoval # breaks on CUDA
      obs-gstreamer
      obs-multi-rtmp # multi-site
      # obs-nvfbc # TODO broken, uncomment later
      obs-pipewire-audio-capture
      obs-tuna # song info
      obs-vaapi
      wlrobs # screen capture for wlroots
    ];
    enableVirtualCamera = true; # set up the v4l2loopback kernel module
  };
  programs.gphoto2.enable = true; # dslr interface
}
