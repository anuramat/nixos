{
  pkgs,
  config,
  lib,
  ...
}:
let
  # TODO mcp; check out extensions and recipes in https://block.github.io/goose/docs/
  config = {
    GOOSE_MODE = "auto";
    GOOSE_MAX_TURNS = 9999999;
  };
  # GOOSE_MODE: auto
  # GOOSE_MODEL: gpt-4.1
  # GOOSE_PROVIDER: github_copilot
  # extensions:
  #   computercontroller:
  #     bundled: true
  #     display_name: Computer Controller
  #     enabled: true
  #     name: computercontroller
  #     timeout: 300
  #     type: builtin
  #   developer:
  #     bundled: true
  #     display_name: Developer Tools
  #     enabled: true
  #     name: developer
  #     timeout: 300
  #     type: builtin
  #   memory:
  #     bundled: true
  #     display_name: Memory
  #     enabled: true
  #     name: memory
  #     timeout: 300
  #     type: builtin
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
