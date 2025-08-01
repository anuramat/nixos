{
  lib,
  hax,
  inputs,
  pkgs,
  ...
}:
{
  plugins = {
    avante = {
      enable = true;
      settings = {
        provider = "copilot";
        # behaviour = {
        #   auto_suggestions = true;
        # };
        providers = {
          copilot = {
            # model = "claude-sonnet-4";
            model = "gpt-4.1";
          };
        };
        # windows = {
        #   ask = {
        #     floating = true;
        #     start_insert = false;
        #   };
        #   edit = {
        #     start_insert = false;
        #   };
        #   input = {
        #     height = 12;
        #     prefix = "";
        #   };
        #   width = 40;
        #   wrap = true;
        # };
      };
    };
    blink-cmp-copilot.enable = true;
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
        filetypes = {
          markdown = false;
        };
        should_attach = hax.vim.lua ''
          function(_, bufname)
            if string.match(bufname, 'notes') then return false end
            return true
          end
        '';
      };
    };
  };
  # TODO mcphub
}
