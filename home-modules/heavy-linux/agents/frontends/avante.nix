# TODO commands (shortcuts); maybe plug into mcp-hub https://ravitemer.github.io/mcphub.nvim/mcp/native/prompts.html
# NOTE supports most types of context files, but only reads the first one
{
  config,
  pkgs,
  osConfig ? null,
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
  # # Scoped keys (recommended)
  # export AVANTE_ANTHROPIC_API_KEY=your-claude-api-key
  # export AVANTE_OPENAI_API_KEY=your-openai-api-key
  # export AVANTE_AZURE_OPENAI_API_KEY=your-azure-api-key
  # export AVANTE_GEMINI_API_KEY=your-gemini-api-key
  # export AVANTE_CO_API_KEY=your-cohere-api-key
  # export AVANTE_AIHUBMIX_API_KEY=your-aihubmix-api-key
  # export AVANTE_MOONSHOT_API_KEY=your-moonshot-api-key

  programs.nixvim = {
    plugins.blink-cmp.settings.sources = {
      per_filetype = {
        AvanteInput = hax.vim.lua ''
          { "avante", inherit_defaults = true }
        '';
      };
      providers.avante = {
        module = "blink-cmp-avante";
        name = "avante";
      };
    };
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
          provider = "cerebras";
          providers = {
            cerebras = {
              endpoint = "https://api.cerebras.ai/v1/chat/completions";
              __inherited_from = "openai";
              model = "qwen-3-coder-480b";
              api_key_name = if osConfig then "cmd:cat ${osConfig.age.secrets.cerebras.path}" else "";
              # extra_request_body = { };
            };
            copilot = {
              model = "gpt-4.1";
            };
          };
        };
      };
    };
  };

  home.activation.mcphub =
    let
      servers =
        let
          rawServers = config.lib.agents.mcp.raw;
          enabledServers = { inherit (rawServers) ddg nixos; };
          disabledServers =
            rawServers
            |> lib.filterAttrs (n: _: !lib.hasAttr n enabledServers)
            |> lib.mapAttrs (_: v: v // { disabled = true; });
        in
        enabledServers // disabledServers;
    in
    config.lib.home.json.set {
      mcpServers = servers;
    } "${config.xdg.configHome}/mcphub/servers.json";
}
