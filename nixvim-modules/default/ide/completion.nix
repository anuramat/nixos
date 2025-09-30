{
  hax,
  pkgs,
  lib,
  ...
}:
let
  inherit (hax.vim) luaf;
  inherit (lib) genAttrs;

  provider = "supermaven"; # "copilot" "llm" "supermaven"

  disabledFiletypes = [
    "markdown"
    "typst"
  ];
  shouldEnableFunc = # lua
    ''
      function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if string.match(bufname, "notes") then return false end
        if string.match(bufname, "/home/anuramat/.local/share/ghq") then return true end
        if string.match(bufname, "/etc/nixos") then return true end
        return false
        end
    '';
in
{
  # TODO https://github.com/netmute/ctags-lsp.nvim
  extraPlugins = [
    pkgs.vimPlugins.blink-cmp-avante
  ];
  plugins = {
    friendly-snippets.enable = true;
    supermaven = {
      enable = provider == "supermaven";
      settings = {
        keymaps = {
          accept_suggestion = "<M-y>";
          clear_suggestions = "<M-e>";
          accept_word = "<M-w>";
        };
        ignore_filetypes = disabledFiletypes;
        condition = luaf ''
          local should_enable = ${shouldEnableFunc}
          return not should_enable()
        '';
      };
    };
    llm = {
      enable = provider == "llm";
    };
    blink-cmp = {
      enable = true;
      settings = {
        # completion = {
        # ghost_text.enabled = true;
        # menu.auto_show = false;
        # ghost_text.show_with_menu = false;
        # };
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
        };
      };
    };
    copilot-lua = {
      enable = provider == "copilot";
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
          hide_during_completion = false;
          debounce = 150;
          keymap = {
            accept = "<M-y>";
            accept-line = "<M-j>";
            accept-word = "<M-w>";
            next = "<M-n>";
            prev = "<M-p>";
            dismiss = "<M-e>";
          };
        };
        filetypes = genAttrs disabledFiletypes (ft: false);
        should_attach = shouldEnableFunc;
      };
    };
  };
}
