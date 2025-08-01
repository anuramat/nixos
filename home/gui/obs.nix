{ pkgs, lib, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval # breaks on CUDA
      obs-gstreamer
      obs-multi-rtmp # multi-site
      # obs-nvfbc # TODO still broken 2025-08-01
      obs-pipewire-audio-capture
      obs-tuna # song info
      obs-vaapi
      wlrobs # screen capture for wlroots
    ];
  };

  xdg.configFile =
    let
      tunaCfg = [
        {
          format = "{title} - {first_artist}";
          last_output = "";
          log_mode = false;
          output = "/tmp/tuna_output.txt";
        }
      ];
    in
    {
      "obs-studio/plugin_config/tuna/outputs.json".text = lib.generators.toJSON { } tunaCfg;
    };
}
