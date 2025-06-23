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
        # tokyo-night-dark
        # stella -- pastel purple bg, otherwise dracula vibes
        # black-metal -- mostly black and white, shades of very faint pastel red and blue otherwise
        # paraiso -- pastel burgundy bg, almost monochrome
        # greenscreen -- green monochrome
        name = "greenscreen";
      in
      "${pkgs.base16-schemes}/share/themes/${name}.yaml";
    # ./elflord.yaml;
  };
}
