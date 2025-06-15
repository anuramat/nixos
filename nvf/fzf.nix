{ }:
{ lib, ... }:
{
  vim = {
    keymaps =
      let
        inherit (lib.nvim.binds) mkKeymap;
        mkmap =
          key: subcmd:
          (mkKeymap "n" "<leader>f${key}" "<cmd>FzfLua ${subcmd}<cr>" { desc = "${subcmd} [fzf]"; });
      in
      [
        # { 'G', 'grep' }, -- useful on large projects
        (mkmap "o" "files")
        (mkmap "O" "oldfiles")
        (mkmap "a" "args")
        (mkmap "b" "buffers")
        (mkmap "m" "marks")

        (mkmap "/" "curbuf")
        (mkmap "g" "live_grep")
        (mkmap "G" "grep_last")

        (mkmap "d" "diagnostics_document")
        (mkmap "D" "diagnostics_workspace")
        (mkmap "s" "lsp_document_symbols")
        (mkmap "S" "lsp_workspace_symbols")
        (mkmap "t" "treesitter")

        (mkmap "r" "resume")
        (mkmap "h" "helptags")
        (mkmap "k" "keymaps")
        (mkmap "p" "builtin")

        (mkKeymap "i" "<C-x><C-f>"
          ''
            function()
              require('fzf-lua').complete_file({
                cmd = 'fd -t f -HL',
                winopts = { preview = { hidden = 'nohidden' } },
              })
            end
          ''
          {
            desc = "path completion";
            lua = true;
          }
        )
      ];
  };
  fzf-lua = {
    enable = true;
    setupOpts = {
      grep = {
        RIPGREP_CONFIG_PATH = {
          _type = "lua-inline";
          expr = "vim.env.RIPGREP_CONFIG_PATH";
        };
        fd_opts = "-c never -t f -HL";
        multiline = 2;
      };
      files = {
        "1" = true; # means "merge with defaults"
        ctrl-q = {
          fn = {
            _type = "lua-inline";
            expr = "require('fzf-lua').actions.file_sel_to_qf";
          };
          prefix = "select-all";
        };
      };
    };
    # { 'G', 'grep' }, -- useful on large projects
  };
}
