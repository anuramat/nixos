{ config, pkgs, ... }:
let
  pkg = config.lib.home.agenixWrapPkg pkgs.litellm (
    t: with t; {
      ANTHROPIC_API_KEY = anthropic;
      CEREBRAS_API_KEY = cerebras;
      GEMINI_API_KEY = gemini;
      GROQ_API_KEY = groq;
      OPENAI_API_KEY = openai;
      OLLAMA_API_KEY = ollama;
      OPENROUTER_API_KEY = openrouter;
      POE_API_KEY = poe;
      ZAI_API_KEY = zai;
    }
  );
  cfg = (pkgs.formats.yaml { }).generate "config.yaml" {
    # include = [
    #   "${config.xdg.configHome}/litellm/github_copilot_models.yaml"
    # ];
    # environment_variables = { };
    general_settings = {
      master_key = "dummy";
    };
    model_list = [
      {
        model_name = "ollama_chat/*";
        litellm_params = {
          model = "ollama_chat/*";
          api_key = "os.environ/OLLAMA_API_KEY";
        };
      }
      {
        model_name = "cerebras/*";
        litellm_params = {
          model = "cerebras/*";
          api_key = "os.environ/CEREBRAS_API_KEY";
        };
      }
      {
        model_name = "anthropic/*";
        litellm_params = {
          model = "anthropic/*";
          api_key = "os.environ/ANTHROPIC_API_KEY";
        };
      }
      {
        model_name = "gemini/*";
        litellm_params = {
          model = "gemini/*";
          api_key = "os.environ/GEMINI_API_KEY";
        };
      }
      {
        model_name = "groq/*";
        litellm_params = {
          model = "groq/*";
          api_key = "os.environ/GROQ_API_KEY";
        };
      }
      {
        model_name = "openai/*";
        litellm_params = {
          model = "openai/*";
          api_key = "os.environ/OPENAI_API_KEY";
        };
      }
      {
        model_name = "github_copilot/*";
        litellm_params = {
          model = "github_copilot/*";
          extra_headers = {
            "Editor-Version" = "vscode/1.85.1";
            "Copilot-Integration-Id" = "vscode-chat";
          };
        };
      }
    ];
    litellm_settings = {
      check_provider_endpoint = true;
    };
  };
in
{
  systemd.user.services.litellm = {
    Unit = {
      Description = "LiteLLM";
      After = [ "network.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkg}/bin/litellm --host 127.0.0.1 --port 11333 --config ${cfg}";
      Restart = "always";
      RestartSec = 3;
    };
  };
  home.packages = [ pkg ];
}
