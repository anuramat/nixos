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
    extensions = (
      let
        servers = {
          inherit (config.lib.agents.mcp.raw)
            zotero
            # tools
            ;
        };
      in
      lib.mapAttrs (
        n: v:
        if !v ? type then
          {
            name = n;
            enabled = true;
            type = "stdio";
            cmd = v.command;
            args = v.args or [ ];
            envs = v.env or { };
          }
        else if v.type == "http" then
          { type = "sse"; }
        else
          throw "oops"
      ) servers
    );
    # // {
    #   memory = {
    #     bundled = true;
    #     display_name = "Memory";
    #     enabled = true;
    #     name = "memory";
    #     timeout = 300;
    #     type = "builtin";
    #   };
    # };
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
        env = {
          CONTEXT_FILE_NAMES = "'[\"AGENTS.md\"]'";
        };
      })
    ];
  };
}
