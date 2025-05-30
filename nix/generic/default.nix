{ cluster, ... }:
{
  imports = [
    ./common
    ./home
    ./mime
    ./shell
    ./overlays
  ] ++ (if cluster.this.server then [ ./server ] else [ ./desktop ]);
}
