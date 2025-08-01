{
  lib,
  hax,
  inputs,
  pkgs,
  ...
}:
{
  # TODO https://github.com/Kaiser-Yang/blink-cmp-avante
  plugins = {
    avante = {
      # NOTE prompt setup is in `agents`
      enable = true;
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
}
