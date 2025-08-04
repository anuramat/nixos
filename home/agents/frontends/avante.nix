# WARN context files are hardcoded in lua/avante/utils/prompts.lua: AGENTS, CLAUDE, OPENCODE, ...
# TODO patch
# TODO commands
# TODO roles
# TODO recursive agents
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
      })
    '';
    plugins = {
      avante = {
        enable = true;
        settings = {
          inherit shortcuts;
          behaviour = {
            auto_approve_tool_permissions = true;
            enable_token_counting = true;
          };
          # system_prompt = agents.instructions.text;
          # TODO reuse system prompt file derivation
          system_prompt =
            let
              path = config.xdg.configFile.${config.lib.agents.mainContextFile}.target;
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
    # "nativeMCPServers.neovim.disabled_prompts" = [ "parrot" ];
  } "${config.xdg.configHome}/mcphub/settings.json";
  #   nativeMCPServers = {
  #     mcphub = {
  #       disabled_tools = [ "toggle_mcp_server" ];
  #       disabled_resources = [
  #         "mcphub://docs"
  #         "mcphub://changelog"
  #         "mcphub://native_server_guide"
  #       ];
  #       disabled_prompts = [ "create_native_server" ];
  #     };
  #     neovim.disabled_prompts = [ "parrot" ];
}
