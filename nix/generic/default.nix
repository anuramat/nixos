{ cluster, ... }:
{
  imports = [
    ./common
    ./home
    ./mime
    ./shell
  ] ++ (if cluster.this.server then [ ./server ] else [ ./desktop ]);
}
