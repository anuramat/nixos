# TODO context files are hardcoded in lua/avante/utils/prompts.lua: AGENTS, CLAUDE, OPENCODE, ...; beg devs
# TODO commands (shortcuts); maybe plug into mcp-hub https://ravitemer.github.io/mcphub.nvim/mcp/native/prompts.html
{
  config,
  pkgs,
  inputs,
  lib,
  hax,
  ...
}:
let
  inherit (config.lib) agents;
  inherit (lib) mapAttrs;

  shortcuts =
    agents.commands
    |> mapAttrs (
      n: v: with v; {
        inherit description;
        name = n;
        prompt = text;
        details = text;
      }
    );

  port = toString 37373;
in
{

  programs.nixvim = {
    extraPlugins = [
      inputs.mcphub.packages.${pkgs.system}.default
    ];
    extraConfigLua = ''
      require("mcphub").setup({
        config = "${config.xdg.configHome}/mcphub/servers.json",
        port = ${port},
        auto_approve = false,
        use_bundled_binary = true,
        cmd = "npx",
        cmdArgs = {"-y", "mcp-hub"},
      })
    '';
    plugins = {
      avante = {
        enable = true;
        settings = {
          inherit shortcuts;
          behaviour = {
            auto_approve_tool_permissions = true;
            enable_token_counting = false;
          };
          system_prompt =
            let
              path = pkgs.writeText "instructions.md" agents.instructions.generic;
            in
            hax.vim.luaf ''
              local hub = require("mcphub").get_hub_instance()
              local prompt = hub and hub:get_active_servers_prompt() or ""
              -- read system prompt from file
              local file = io.open("${path}", "r")
              if file then
                local instructions = file:read("*a")
                file:close()
                prompt = prompt .. "\n" .. instructions
              end
              return prompt
            '';
          custom_tools = hax.vim.luaf ''
            return {
              require("mcphub.extensions.avante").mcp_tool(),
            }
          '';
          provider = "copilot";
          providers = {
            copilot = {
              # model = "claude-sonnet-4";
              model = "gpt-4.1";
            };
          };
        };
      };
    };
  };

  home.activation.mcphub = config.lib.home.json.set {
    mcpServers = config.lib.agents.mcp.raw;
  } "${config.xdg.configHome}/mcphub/servers.json";
}
