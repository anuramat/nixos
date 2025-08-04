{
  pkgs,
  config,
  ...
}:
let
  # TODO
  config = {
    GOOSE_MODE = "auto";
    GOOSE_MAX_TURNS = 9999999;
  };
in
{
  home.packages = [
    pkgs.goose-cli
    (config.lib.agents.mkSandbox {
      package = pkgs.goose-cli;
      wrapperName = "gse";
    })
  ];
}
