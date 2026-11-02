{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  # https://flake.parts/options/git-hooks-nix.html
  settings.hooks = {
    treefmt.enable = true;
    statix.enable = true;
    deadnix = {
      enable = true;
      settings.noLambdaArg = true;
      excludes = [ "hardware-configuration\\.nix$" ];
    };
    nix-parse = {
      enable = true;
      entry = "${pkgs.nix}/bin/nix-instantiate --extra-experimental-features pipe-operators --store dummy:// --parse --quiet";
      files = "\\.nix$";
    };
    shellcheck = {
      enable = true;
      args = [
        "--enable=all"
        "--external-sources"
        "--exclude=${lib.concatStringsSep "," inputs.self.consts.excludeShellChecks}"
      ];
    };
    yamllint.enable = true;
  };
}
