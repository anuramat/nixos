{ pkgs, inputs, ... }:
{
  # Use nixcats neovim
  # home.packages = [ myNeovim ];

  # Set as default editor
  # home.sessionVariables = {
  #   EDITOR = "nvim";
  #   VISUAL = "nvim";
  # };

  # Disable home-manager's neovim to avoid conflicts
  programs.neovim.enable = false;

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
}
