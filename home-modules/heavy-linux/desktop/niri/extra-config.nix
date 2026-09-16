# plain-kdl escape hatch for settings niri-flake doesn't expose
{
  lib,
  config,
  options,
  inputs,
  ...
}:
{
  options.programs.niri.extraConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
  };
  config.programs.niri.config =
    inputs.niri.lib.kdl.serialize.nodes options.programs.niri.config.default
    + "\n"
    + config.programs.niri.extraConfig;
}
