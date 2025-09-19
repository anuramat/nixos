{ hax, pkgs, ... }:
{
  # TODO https://github.com/netmute/ctags-lsp.nvim
  extraPlugins = [
    pkgs.vimPlugins.blink-cmp-avante
  ];
  plugins = {
    friendly-snippets.enable = true;
    # llm.enable = true;
    blink-cmp = {
      enable = true;
      settings = {
        # completion = {
        #   ghost_text.enabled = true;
        #   menu.auto_show = false;
        #   ghost_text.show_with_menu = false;
        # };
        sources = {
          providers = {
            # copilot = {
            #   async = true;
            #   name = "copilot";
            #   score_offset = 100;
            # };
          };
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
            # "copilot"
          ];
        };
      };
    };
    # blink-copilot.enable = true;
    copilot-lua = {
      enable = true;
      settings = {
        # <https://github.com/microsoft/vscode/blob/be75065e817ebd7b6250a100cf5af78bb931265b/src/vs/platform/telemetry/common/telemetry.ts#L87>
        server_opts_overrides = {
          settings = {
            telemetry.telemetryLevel = "off";
          };
        };
        panel = {
          enabled = false;
        };
        suggestion = {
          enabled = true;
          auto_trigger = true;
          keymap = {
            accept = "<M-y>";
            next = "<M-n>";
            prev = "<M-p>";
            dismiss = "<M-e>";
          };
        };
        filetypes = {
          markdown = false;
        };
        should_attach = hax.vim.lua ''
          function(_, bufname)
            if string.match(bufname, 'notes') then return false end
            if string.match(bufname, '/home/anuramat/.local/share/ghq') then return true end
            if string.match(bufname, '/etc/nixos') then return true end
            return false
          end
        '';
      };
    };
  };
}
