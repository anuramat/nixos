{ cluster, ... }:
{
  imports = [
    ./common
    ./home
    ./mime
    ./shell
    ./overlays.nix
  ] ++ (if cluster.this.server then [ ./server ] else [ ./desktop ]);
}
