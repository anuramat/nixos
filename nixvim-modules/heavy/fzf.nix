{ config, ... }:
let
  inherit (config.lib)
    keymap
    cmd
    ;
in
{
  keymaps =
    let
      mapAction = key: action: cmd "n" "<leader>f${key}" "FzfLua ${action}" "fzf: ${action}";
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
      (keymap "i" "<C-x><C-f>" {
        __raw = ''function() require("fzf-lua").complete_file({ cmd = "fd -t f -HL", winopts = { preview = { hidden = "nohidden" } } }) end'';
      } "path completion")
    ];

  plugins.fzf-lua = {
    enable = true;
    settings = {
      grep = {
        RIPGREP_CONFIG_PATH.__raw = "vim.env.RIPGREP_CONFIG_PATH";
        multiline = 2;
      };
      files.fd_opts = "-c never -t f -t l -HL";
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
