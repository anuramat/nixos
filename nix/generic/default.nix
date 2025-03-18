{ cluster, ... }:
{
  imports = [
    ./common
    ./home
    ./mime
    ./shell
  ] ++ (if cluster.this.desktop then ./desktop else [ ]);
}
