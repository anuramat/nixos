{ pkgs, ... }:
{
  stylix = {
    enable = true;
    autoEnable = true;
    fonts = {
      monospace = {
        name = "Hack Nerd Font";
      };
      sizes = {
        applications = 13;
        desktop = 10;
        popups = 10;
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
