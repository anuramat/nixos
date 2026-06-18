{ inputs, config, ... }:
{
  imports = [
    ./editor.nix
    ./gui
    ./lang
    ./typst.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
    ./packages.nix
  ];

  home = {
    activation = {
      exercismConfig = config.lib.home.json.set {
        workspace = config.xdg.dataHome + "/exercism";
      } (config.xdg.configHome + "/exercism/user.json");
    };
  };
}
