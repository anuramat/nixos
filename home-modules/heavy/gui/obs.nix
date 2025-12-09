{ pkgs, lib, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval # WARN takes ages to build
      obs-pipewire-audio-capture
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
