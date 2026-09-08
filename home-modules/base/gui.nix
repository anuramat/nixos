{ lib, ... }:
{
  options.gui = lib.mkEnableOption "graphical session";
}
