{ pkgs, inputs, ... }:
{
  home.packages = [ inputs.nixvim-config.packages.${system}.default ];
  programs = {
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
