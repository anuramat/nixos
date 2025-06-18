{
  keymaps =
    let
      map = key: action: {
        mode = "n";
        key = "<leader>f" + key;
        action = "<cmd>FzfLua ${action}<cr>";
        options = {
          desc = "${action} [fzf]";
        };
      };
    in
    [
      (map "o" "files")
      (map "O" "oldfiles")
      (map "a" "args")
      (map "b" "buffers")
      (map "m" "marks")

      (map "/" "curbuf")
      (map "g" "live_grep")
      (map "G" "grep_last")
      # (map "G" "grep") # useful on large projects

      (map "d" "diagnostics_document")
      (map "D" "diagnostics_workspace")
      (map "s" "lsp_document_symbols")
      (map "S" "lsp_workspace_symbols")
      (map "t" "treesitter")

      (map "r" "resume")
      (map "h" "helptags")
      (map "k" "keymaps")
      (map "p" "builtin")
      {
        mode = "i";
        key = "<C-x><C-f>";
        action.__raw = ''
          function()
            require('fzf-lua').complete_file({
              cmd = 'fd -t f -HL',
              winopts = { preview = { hidden = 'nohidden' } },
            })
          end
        '';
        options.desc = "path completion";
      }
    ];

  plugins.fzf-lua = {
    enable = true;
    settings = {
      grep = {
        RIPGREP_CONFIG_PATH.__raw = "vim.env.RIPGREP_CONFIG_PATH";
        fd_opts = "-c never -t f -HL";
        multiline = 2;
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
