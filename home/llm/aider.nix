{
  lib,
  ...
}:
let
  toYAML = lib.generators.toYAML { };
in
{
  home.file = {
    ".aider.conf.yml".text = toYAML {
      openai-api-base = "https://api.githubcopilot.com";
      model = "openai/claude-sonnet-4";
      weak-model = "openai/gpt-4.1";
      show-model-warnings = false;
      cache-prompts = true;
      cache-keepalive-pings = "3";
      map-tokens = "0";
      read = [
        "CLAUDE.md"
        "~/.claude/CLAUDE.md"
      ];
      dark-mode = true;
      light-mode = false;
    };

    ".aider.model.settings.yml".text = toYAML [
      {
        name = "aider/extra_params";
        extra_params = {
          extra_headers = {
            Editor-Version = "aider/0.84.0";
            Copilot-Integration-Id = "vscode-chat";
          };
        };
      }
    ];
  };
}
