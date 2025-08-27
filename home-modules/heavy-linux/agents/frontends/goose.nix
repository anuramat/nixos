{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:
let
  # TODO mcp; check out extensions and recipes in https://block.github.io/goose/docs/
  # TODO turn extensions on/off based on project
  gooseConfig = {
    GOOSE_MODE = "auto";
    GOOSE_MAX_TURNS = 9999999;
    GOOSE_MODEL = "gpt-4.1";
    GOOSE_PROVIDER = "github_copilot";
    OLLAMA_HOST =
      let
        port = toString osConfig.services.llama-cpp.port;
      in
      "localhost:${port}";
    extensions =
      (lib.mapAttrs (
        n: v:
        if !v ? type then
          {
            type = "stdio";
            cmd = v.command;
            inherit (v) args;
            envs = v.env;
          }
        else if v.type == "http" then
          { type = "sse"; }
        else
          throw "oops"
      ) config.lib.agents.mcp)
      // {
        computercontroller = {
          bundled = true;
          display_name = "Computer Controller";
          enabled = true;
          name = "computercontroller";
          timeout = 300;
          type = "builtin";
        };
        developer = {
          bundled = true;
          display_name = "Developer Tools";
          enabled = true;
          name = "developer";
          timeout = 300;
          type = "builtin";
        };
        memory = {
          bundled = true;
          display_name = "Memory";
          enabled = true;
          name = "memory";
          timeout = 300;
          type = "builtin";
        };
      };
  };
in
{
  home = {
    activation = {
      goose = config.lib.home.yaml.set gooseConfig "${config.xdg.configHome}/goose/config.yaml";
    };

    packages = [
      pkgs.goose-cli
      (config.lib.agents.mkSandbox {
        package = pkgs.goose-cli;
        wrapperName = "gse";
      })
    ];
  };
}
