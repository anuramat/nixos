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
    # stella
    # black-metal
    # tokyo-night-dark.yaml
    base16Scheme = "${pkgs.base16-schemes}/share/themes/stella";
  };
}
