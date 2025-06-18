{ cluster, ... }:
{
  imports = [ ./base ] ++ (if cluster.this.server then [ ./remote ] else [ ./local ]);
}
