{
  pkgs,
  inputs,
  ...
}:
{
  stylix.targets.nixvim.plugin = "base16-nvim";
  programs = {
    nixvim = {
      enable = true;
      imports = [
        inputs.self.nixvimModules.default
      ];
      defaultEditor = true;
    };
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
  home.packages = with pkgs; [
    vis
  ];
}
