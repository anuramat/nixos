{ lib, pkgs, ... }:
{
  plugins = {

    imports = [
      ./completion.nix
      ./format.nix
      ./lint.nix
      ./lsp.nix
      ./tasks.nix
      ./dap.nix
    ];

  };
}
