{ config, ... }:
{
  imports = [
    ./common
    ./home
    ./mime
    ./shell
  ] ++ (if !config.server then ./desktop else [ ]);
}
