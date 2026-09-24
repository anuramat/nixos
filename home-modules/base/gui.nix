{ lib, ... }:
{
  options.gui = lib.mkOption {
    type = lib.types.enum [
      "none"
      "wayland"
      "darwin"
    ];
    default = "none";
    description = "graphical session";
  };
}
