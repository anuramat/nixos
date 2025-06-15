{ pkgs, inputs, ... }:
{
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
