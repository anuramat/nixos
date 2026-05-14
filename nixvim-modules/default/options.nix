{ lib, ... }:
{
  options.lib = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    internal = true;
  };
}
