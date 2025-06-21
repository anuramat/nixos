{ hax, ... }:
{
  keymaps =
    let
      set = key: action: hax.vim.set ("<leader>f" + key) "${action} [fzf]";
    in
    [
      (set "o" "files")
      (set "O" "oldfiles")
      (set "a" "args")
      (set "b" "buffers")
      (set "m" "marks")

      (set "/" "curbuf")
      (set "g" "live_grep")
      (set "G" "grep_last")
      # (map "G" "grep") # useful on large projects

      (set "d" "diagnostics_document")
      (set "D" "diagnostics_workspace")
      (set "s" "lsp_document_symbols")
      (set "S" "lsp_workspace_symbols")
      (set "t" "treesitter")

      (set "r" "resume")
      (set "h" "helptags")
      (set "k" "keymaps")
      (set "p" "builtin")
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
