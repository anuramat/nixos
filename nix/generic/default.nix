{
  pkgs,
  config,
  cluster,
  ...
}:
{
  imports = [
    ./common
    ./mime
    ./shell
    ./overlays
  ] ++ (if cluster.this.server then [ ./server ] else [ ./desktop ]);

  home-manager = {
    backupFileExtension = "hmbackup";
    useGlobalPkgs = true;
    useUserPackages = true;
    # WARN -- home manager expects a module
    # so if you pass a function, it's gonna apply it to the home manager args, not nixos
    # TODO separate hm from nixos completely
    # the first step would be to move config.user option entirely to home manager
    # in some places it's gonna have to be hardcoded, but that probably makes more sense
    users.${config.user.username} = import ./home;
  };

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
}
