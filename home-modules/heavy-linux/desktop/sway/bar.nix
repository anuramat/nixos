{ ... }:
{
  programs = {
    # sway.config.bars = [ ];
    i3status-rust = {
      enable = true;
      bars = { };
    };
  };
  #       modules = {
  #         modules-left = [
  #           "pulseaudio"
  #           "backlight"
  #           "idle_inhibitor"
  #           "sway/language"
  #           "mpris"
  #         ];
  #         modules-center = [
  #           "custom/rec"
  #           "sway/workspaces"
  #           "sway/scratchpad"
  #         ];
  #         modules-right = [
  #           "tray"
  #           "disk"
  #           "battery"
  #           "clock"
  #         ];
  #       };
}
