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

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
}
