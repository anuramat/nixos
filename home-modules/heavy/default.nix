{ config, ... }:
{
  imports = [
    ./editor.nix
    ./gui.nix
    ./fonts.nix
    ./jupyter.nix
    ./lang
    ./typst.nix
    ./packages.nix
    ./terminals.nix
  ];

  home = {
    activation = {
      exercismConfig = config.lib.home.json.set {
        workspace = config.xdg.dataHome + "/exercism";
      } (config.xdg.configHome + "/exercism/user.json");
    };
  };
}
