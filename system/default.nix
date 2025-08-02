{ cluster, ... }:
{
  imports = [
    ./base
  ]
  ++ (
    if !cluster.this.server then
      [
        ./local
      ]
    else
      [ ]
  );
}
