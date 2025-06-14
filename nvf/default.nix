{ pkgs, lib, ... }:
{
  config.vim = {
    keymaps =
      let
        inherit (lib.nvim.binds) mkKeymap;
        mkmap =
          key: subcmd:
          (mkKeymap "n" "<leader>f${key}" "<cmd>FzfLua ${subcmd}<cr>" { desc = "fzf: ${subcmd}"; });
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

    luaConfigPost = # lua
      ''
        vim.cmd('runtime ${./base.vim}')
        vim.diagnostic.config({
          severity_sort = true,
          update_in_insert = true,
          signs = false,
        })
        vim.deprecate = function() end
      '';

    # why two?
    # treesitter.autotagHtml = true;
    # languages.html.treesitter.autotagHtml = true;

    git = {
      gitlinker-nvim.enable = true;
      gitsigns.enable = true;
      vim-fugitive.enable = true;
    };

    filetree.neo-tree.enable = true;
    formatter.conform-nvim.enable = true;
    fzf-lua = {
      enable = true;
      setupOpts = {
        grep = {
          RIPGREP_CONFIG_PATH = "vim.env.RIPGREP_CONFIG_PATH";
          fd_opts = "-c never -t f -HL";
          multiline = 2;
        };
        files = {
          "1" = true;
          ctrl-q = {
            fn = "require('fzf-lua').actions.file_sel_to_qf";
            prefix = "select-all";
          };
        };
      };
      # { 'G', 'grep' }, -- useful on large projects
    };
    lazy.enable = true;
    notes.todo-comments.enable = true;
    ui.colorizer.enable = true;

    mini = {
      ai.enable = true;
      align.enable = true;
      bracketed.enable = true;
    };
    treesitter = {
      context.enable = true;
      textobjects.enable = true;
    };
    utility = {
      images.image-nvim = {
        enable = true;
        setupOpts.backend = "kitty";
      };
      outline.aerial-nvim.enable = true;
      diffview-nvim.enable = true;
      oil-nvim.enable = true;
      surround.enable = true;
    };
    visuals = {
      fidget-nvim.enable = true;
      rainbow-delimiters.enable = true;
    };

    languages = {
      clang.enable = true;
      go.enable = true;
      html.enable = true;
      lua.enable = true;
      markdown.enable = true;
      nix.enable = true;
      python.enablee = true;
      rust.enable = true;
      ts.enable = true;
      zig.enable = true;
    };

    autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
    };

    lsp = {
      enable = true;
      inlayHints.enable = true;
      lspconfig.enable = true;
      formatOnSave = true;
      lightbulb.enable = true;
      otter-nvim.enable = true;
    };

    debugger.nvim-dap = {
      enable = true;
      ui.enable = true;
    };

    assistant = {
      avante-nvim.enable = true;
      copilot.enable = true;
    };

    viAlias = false;
    vimAlias = false;
  };
}
