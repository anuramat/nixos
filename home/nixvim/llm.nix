{
  lib,
  inputs,
  pkgs,
  ...
}:
{
  plugins = {
    avante = {
      enable = true;
      package = pkgs.vimPlugins.avante-nvim.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "yetone";
          repo = "avante.nvim";
          rev = "v0.0.25";
          hash = "sha256-lmyooXvQ+Cqv/6iMVlwToJZMFePSWoVzuGVV7jsSOZc=";
        };
        version = "v0.0.25";
      });
      settings = {
        provider = "copilot";
        behaviour = {
          auto_suggestions = false;
        };
        providers = {
          copilot = {
            model = "claude-sonnet-4";
          };
        };
        windows = {
          ask = {
            floating = true;
            start_insert = false;
          };
          edit = {
            start_insert = false;
          };
          input = {
            height = 12;
            prefix = "";
          };
          width = 40;
          wrap = true;
        };
      };
    };
    copilot-lua = {
      enable = true;
      settings = {
        # <https://github.com/microsoft/vscode/blob/be75065e817ebd7b6250a100cf5af78bb931265b/src/vs/platform/telemetry/common/telemetry.ts#L87>
        server_opts_overrides = {
          settings.telemetry.telemetryLevel = "off";
        };
        panel = {
          enabled = false;
        };
        suggestion = {
          enabled = false;
        };
      };
    };
  };
  # TODO mcphub
}
