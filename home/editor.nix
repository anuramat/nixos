{ pkgs, inputs, ... }:
{
  programs = {
    nixvim = {
      enable = true;
      config = inputs.self.packages.${pkgs.stdenv.system}.neovim.config;
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
    vscode
    vis
    zed-editor
  ];
}
