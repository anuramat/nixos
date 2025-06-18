{
  config,
  pkgs,
  lib,
  user,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./lang
    ./misc.nix
    ./email.nix
    ./mime
    ./llm
    ./term.nix
    ./editor.nix
    ./secret.nix
    ./theme.nix
    ./desktop
    ./cli
  ];

  xdg.enable = true; # set xdg basedir vars in .profile

  programs.home-manager.enable = true; # TODO huh? what does this do

  home = {
    preferXdgDirectories = true;
    activation = {
      removeBrokenConfigLinks =
        lib.hm.dag.entryBefore [ "writeBoundary" ] # bash
          ''
            args=("${config.xdg.configHome}" -maxdepth 1 -xtype l)
            [ -z "''${DRY_RUN:+set}" ] && args+=(-delete) 
            [ -n "''${VERBOSE:+set}" ] && args+=(-print)
            run find "''${args[@]}"
          '';
    };
  };
}
