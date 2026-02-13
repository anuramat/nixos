{
  lib,
  pkgs,
  config,
  osConfig ? null,
  ...
}:
let
  inherit (lib) mapAttrs getExe;
  inherit (config.lib) agents;

  # glm = "cerebras/zai-glm-4.7";
  glm = "zai-coding-plan/glm-5";

  agent =
    let
      ro = {
        bash = false;
        patch = false;
        edit = false;
        write = false;
        task = false;
      };
      default = {
        plan = {
          model = glm;
          tools = ro;
        };
        build = {
          model = glm;
        };
        general = {
          model = glm;
        };
      };
    in
    default;

  tokens =
    t: with t; {
      inherit
        cerebras
        groq
        ollama
        openrouter
        zai
        ;
    };
  keys = mapAttrs (n: _: "{env:${n}}") osConfig.age.secrets;
  provider =
    let
      # TODO tidy gpt5 models
      gpt5models =
        let
          gptOutputOptions = {
            reasoningEffort = "medium";
            textVerbosity = "low";
          };
        in
        {
          gpt-5.options = gptOutputOptions;
          gpt-5-mini.options = gptOutputOptions;
        };
    in
    {
      openrouter.options.apiKey = keys.openrouter;
      ollama-cloud.options.apiKey = keys.ollama;
      cerebras.options.apiKey = keys.cerebras;
      zai-coding-plan.options.apiKey = keys.zai;
      groq.options.apiKey = keys.groq;
      github-copilot.models = gpt5models;
      openai = {
        options = {
          # apiKey = keys.openai;
          reasoningSummary = "detailed";
          textVerbosity = "low";
          include = [
            "reasoning.encrypted_content"
          ];
        };
      };
    };

  lsp = {
    custom-lsp = {
      command = [
        (getExe pkgs.tinymist)
        "lsp"
      ];
      extensions = [
        ".typ"
      ];
    };
  };

  mcp =
    let
      mkZaiMcp = url: {
        inherit url;
        type = "remote";
        headers = {
          Authorization = "Bearer ${keys.zai}";
        };
      };
    in
    {
      web-search-prime = mkZaiMcp "https://api.z.ai/api/mcp/web_search_prime/mcp";
      web-reader = mkZaiMcp "https://api.z.ai/api/mcp/web_reader/mcp";
      zread = mkZaiMcp "https://api.z.ai/api/mcp/zread/mcp";
    };

  notifications = # javascript
    ''
      export const NotificationPlugin = async ({ client, $ }) => {
      	return {
      		event: async ({ event }) => {
      			// Send notification on session completion
      			if (event.type === "session.idle") {
      				await $`notify-send -a opencode "OpenCode" Session completed!"`;
      			}
      		},
      	};
      };
    '';

  # TODO put into config file as well
  command =
    agents.commands
    |> mapAttrs (
      _: v: {
        inherit (v) description;
        template = v.text;
        # model, agent, subtask: bool
      }
    );

in
{
  xdg.configFile = {
    "opencode/AGENTS.md".text = agents.instructions.generic;
    "opencode/plugin/notifications.js".text = notifications;
  };
  home = {
    # tui state
    activation.opencodeKv = config.lib.home.json.set {
      openrouter_warning = false;
      terminal_title_enabled = false;
      sidebar = "auto"; # auto | hide
      thinking_visibility = false;
      timestamps = "hide"; # show | hide
      tool_details_visibility = false;
      assistant_metadata_visibility = true;
      scrollbar_visible = false;
      animations_enabled = true;
      theme_mode = "dark";
    } (config.xdg.stateHome + "/opencode/kv.json");
    activation.opencodeSettings = config.lib.home.json.set {
      inherit
        provider
        agent
        command
        mcp
        lsp
        ;
      plugin = [
      ];
      small_model = glm;
      autoupdate = false;
      instructions = [ "AGENTS.md" ];
      tools.webfetch = false;
      share = "disabled";
      keybinds.editor_open = "<leader>ctrl+e,<leader>e";
    } (config.xdg.configHome + "/opencode/opencode.json");
    packages = [
      (agents.mkPackages {
        agentDir = "opencode";
        package = pkgs.opencode;
        inherit tokens;
        env = {
          OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
        };
      })
    ];
  };
}
