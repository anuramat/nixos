{
  pkgs,
  hax,
  inputs,
  osConfig ? null,
  ...
}:
{
  stylix.targets = {
    neovim.plugin = "base16-nvim";
  };
  programs = {
    nixvim = {
      enable = true;
      imports = [
        inputs.self.nixvimModules.default
      ];
      defaultEditor = true;
      _module.args = {
        # TODO is this the right/official way? underscore looks sketchy
        inherit inputs hax;
      }
      // (if osConfig != null then { inherit osConfig; } else { osConfig = null; });
    };
    helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
        };
      };
    };
  };
  home.packages = with pkgs; [
    vis
    zeditor
  ];
}
