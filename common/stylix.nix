{ pkgs, ... }:
{
  stylix = {
    opacity.popups = 0.8;
    polarity = "dark";
    cursor = {
      name = "Hackneyed";
      package = pkgs.hackneyed;
      size = 20;
    };
    enable = true;
    autoEnable = true;
    fonts = {
      monospace = {
        name = "Hack Nerd Font";
      };
      sizes = {
        applications = 13;
        desktop = 11;
        popups = 11;
        terminal = 13;
      };
    };
    base16Scheme =
      let
        # stella black-metal tokyo-night-dark
        name = "stella";
      in
      "${pkgs.base16-schemes}/share/themes/${name}.yaml";
  };
}
