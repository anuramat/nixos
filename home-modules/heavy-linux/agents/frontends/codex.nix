{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  inherit (lib) mapAttrs';
  inherit (config.lib) agents;

  codexHome = config.xdg.configHome + "/codex";
  codexCfgPath = codexHome + "/config.toml";

  skillFiles =
    agents.commands
    |> mapAttrs' (
      n: v: {
        name = "codexSkill-" + n;
        value =
          let
            text = v.withFM {
              name = n;
              inherit (v) description;
            };
            file = pkgs.writeTextFile {
              name = "${n}-SKILL.md";
              inherit text;
            };
          in
          config.lib.home.mkGenericActivationScript file (codexHome + "/skills/${n}/SKILL.md");
      }
    );

  codexTomlCfg =
    let
      # https://github.com/openai/codex/blob/main/codex-rs/config.md
      cfg = {
        notice = {
          hide_full_access_warning = true;
          hide_gpt5_1_migration_prompt = true;
          "hide_gpt-5.1-codex-max_migration_prompt" = true;
          model_migrations = {
            "gpt-5.1-codex-max" = "gpt-5.2-codex";
          };
        };
        hide_agent_reasoning = false;
        show_raw_agent_reasoning = true;
        model_reasoning_summary = "detailed";

        model_reasoning_effort = "medium";
        model_verbosity = "low";
        model = "gpt-5.2-codex";

        features = {
          web_search_request = true;
        };

        projects = {
          "/etc/nixos" = {
            trust_level = "trusted";
          };
        };

        mcp_servers = {
          # inherit (config.lib.agents.mcp.raw) ddg;
        };
        profiles = {
          oss = {
            model = "llama_cpp/dummy";
            model_provider = "litellm";
          };
          openrouter = {
            model = "z-ai/glm-4.6";
            model_provider = "openrouter";
            query_params = {
              provider = {
                only = [ "cerebras" ];
              };
            };
          };
        };
        # experimental_resume = "${codexHome}/history.jsonl";
        model_providers = {
          openrouter = {
            name = "openrouter";
            base_url = "https://openrouter.ai/api/v1";
            env_key = "OPENROUTER_API_KEY";
            # wire_api = "responses";
          };
        }
        // (
          if osConfig != null && osConfig.services.llama-cpp.enable then
            {
              litellm = {
                name = "litellm";
                base_url =
                  let
                    port = "11333";
                  in
                  "http://localhost:${port}";
                experimental_bearer_token = "dummy";
                # wire_api = "responses";
              };
            }
          else
            { }
        );
        notify =
          let
            notifier = pkgs.writeShellApplication {
              name = "codex-notifier";
              runtimeInputs = with pkgs; [
                jq
                findutils
                libnotify
              ];
              text = ''
                notify-send -a codex "Codex" "$(jq .last-assistant-message -r)"
              '';
            };
          in
          [ notifier ];
      };
    in
    (pkgs.formats.toml { }).generate "codex-config.toml" cfg;
  env = {
    CODEX_HOME = codexHome;
  };
  pkg = config.lib.agents.mkPackages {
    binName = "codex";
    package = pkgs.codex;
    args = [ "--dangerously-bypass-approvals-and-sandbox" ];
    inherit env;
    agentDir = null;
    extraRwDirs = [
      codexHome
    ];
  };
in
{
  home.sessionVariables = env;
  home = {
    packages = [ pkg ];
    activation = {
      codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run cat ${codexTomlCfg} > "${codexCfgPath}";
      '';
    }
    // skillFiles;
  };
  xdg.configFile = {
    "codex/AGENTS.md" = {
      text = config.lib.agents.instructions.codex;
    };
  };
}
