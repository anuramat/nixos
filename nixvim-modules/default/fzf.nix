{ config, ... }:
let
  inherit (config.lib) lua luaf keymap;
in
{
  keymaps =
    let
      mapAction = key: action: keymap "n" "<leader>f${key}" "<cmd>FzfLua ${action}<cr>" "fzf: ${action}";
    in
    [
      (mapAction "o" "files")
      (mapAction "O" "oldfiles")
      (mapAction "a" "args")
      (mapAction "b" "buffers")
      (mapAction "m" "marks")

      (mapAction "/" "curbuf")
      (mapAction "g" "live_grep")
      (mapAction "G" "grep_last")
      # (keymap "G" "grep") # useful on large projects

      (mapAction "d" "diagnostics_document")
      (mapAction "D" "diagnostics_workspace")
      (mapAction "s" "lsp_document_symbols")
      (mapAction "S" "lsp_workspace_symbols")
      (mapAction "t" "treesitter")

      (mapAction "r" "resume")
      (mapAction "h" "helptags")
      (mapAction "k" "keymaps")
      (mapAction "p" "builtin")
      (config.lib.keymap "i" "<C-x><C-f>"
        (luaf ''require("fzf-lua").complete_file({ cmd = "fd -t f -HL", winopts = { preview = { hidden = "nohidden" } } })'')
        "path completion"
      )
    ];

  plugins.fzf-lua = {
    enable = true;
    settings =
      let
        fd_opts = "-c never -t f -t l -HL";
      in
      {
        grep = {
          RIPGREP_CONFIG_PATH = lua "vim.env.RIPGREP_CONFIG_PATH";
          inherit fd_opts;
          multiline = 2;
        };
        files = {
          inherit fd_opts;
        };
        actions.files = {
          __unkeyed-1 = true; # merge with defaults
          "ctrl-q" = {
            fn.__raw = "require('fzf-lua').actions.file_sel_to_qf";
            prefix = "select-all";
          };
        };
      };
  };
}
