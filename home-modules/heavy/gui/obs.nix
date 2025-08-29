{ pkgs, lib, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval # FUCK tensorRT doesn't use the GPU somehow, yet increases CPU usage???
      obs-multi-rtmp # multi-site
      obs-pipewire-audio-capture
      obs-tuna # song info, not really using since waybar shows the song
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
