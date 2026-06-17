{
  config,
  lib,
  ...
}:
let
  inherit (config.lib) lua;
  inherit (lib) genAttrs;

  disabledFiletypes = [
    "markdown"
    "typst"
    "text"
    "json"
    "yaml"
    "todotxt"
    "toml"
    "grug-far"
    "grug-far-history"
  ];
  # NOTE: calls back home even when disabled
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
  plugins = {
    friendly-snippets.enable = true;
    blink-cmp = {
      enable = true;
      settings = {
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
        filetypes = genAttrs disabledFiletypes (_ft: false);
        should_attach = lua shouldEnableFunc;
      };
    };
  };
}
