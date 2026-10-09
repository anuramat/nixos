{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # obs-backgroundremoval # WARN takes ages to build
      obs-pipewire-audio-capture
      obs-vaapi
      wlrobs # screen capture for wlroots
    ];
  };
}
