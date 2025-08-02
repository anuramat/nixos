{ hax, ... }:
{
  # TODO https://github.com/netmute/ctags-lsp.nvim
  plugins = {
    friendly-snippets.enable = true;
    blink-cmp = {
      enable = true;
      settings.sources = {
        providers.copilot = {
          async = true;
          module = "blink-cmp-copilot";
          name = "copilot";
          score_offset = 100;
        };
        default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
          "copilot"
        ];
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
}
