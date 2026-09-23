{
  config,
  pkgs,
  inputs,
  ...
}:
{
  stylix.targets.nixvim.plugin = "base16-nvim";
  programs = {
    nixvim.imports = [ inputs.self.nixvimModules.heavy ];
    helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
        };
      };
    };
    zed-editor = {
      enable = true;
    };
  };
  home.packages = [ pkgs.vis ] ++ config.programs.nixvim.tools;
}
