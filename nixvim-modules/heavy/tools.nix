# SLOP
# formatters and linters auto-installed by conform and nvim-lint, exported so
# home-manager can put them on the user's PATH too
{
  lib,
  options,
  config,
  ...
}:
{
  options.tools = lib.mkOption { type = with lib.types; listOf package; };
  config = {
    tools =
      options.extraPackages.definitionsWithLocations
      |> lib.filter (d: builtins.match ".*/plugins/by-name/(conform-nvim|lint)(/.*)?" d.file != null)
      |> lib.concatMap (d: d.value)
      |> lib.filter (p: p != null);
    assertions = [
      {
        assertion = config.tools != [ ];
        message = "nixvim tools list is empty; did nixvim move its conform-nvim/lint modules?";
      }
    ];
  };
}
