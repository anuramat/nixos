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
      gitlinker-nvim = {
        enable = true;
        setupOpts = {
          opts = {
            add_current_line_on_normal_mode = false;
            print_url = true;
          };
        };
      };
      gitsigns = {
        enable = true;
        setupOpts = {
          sign_priority = 1000;
          signs_staged = {
            add = {
              text = "▎";
            };
            change = {
              text = "▎";
            };
            delete = {
              text = "▎";
            };
            topdelete = {
              text = "▎";
            };
            changedelete = {
              text = "▎";
            };
            untracked = {
              text = "▎";
            };
          };
        };
        mappings = {
          stageHunk = "<leader>gs";
          stageBuffer = "<leader>gS";
          resetHunk = "<leader>gr";
          resetBuffer = "<leader>gR";
          blameLine = "<leader>gb";
          previewHunk = "<leader>gp";
          diffThis = "<leader>gd";
          nextHunk = "]h";
          previousHunk = "[h";
        };
      };
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
          "1" = true; # means "merge with defaults"
          ctrl-q = {
            fn = "require('fzf-lua').actions.file_sel_to_qf";
            prefix = "select-all";
          };
        };
      };
      # { 'G', 'grep' }, -- useful on large projects
    };
    lazy.enable = true;
    notes.todo-comments = {
      enable = true;
      setupOpts = {
        signs = false;
        # TODO turn off mappings
        highlight = {
          keyword = "bg"; # only highlight the word itself
          pattern = ''<(KEYWORDS)>''; # vim regex
          multiline = false;
        };
        search = {
          pattern = ''\b(KEYWORDS)\b''; # ripgrep
        };
      };
    };
    ui.colorizer = {
      enable = true;
      setupOpts = {
        filetypes = [
          "css"
          "yaml"
        ];
      };
    };

    mini = {
      align.enable = true;
      bracketed.enable = true;
    };
    treesitter = {
      context = {
        enable = true;
        setupOpts = {
          enable = true;
          max_lines = 1;
          min_window_height = 20;
          line_numbers = true;
          multiline_threshold = 1;
          trim_scope = "outer";
          mode = "cursor";
          zindex = 20; # TODO why 20?
        };
      };
      textobjects.enable = true;
    };
    utility = {
      images.image-nvim = {
        enable = true;
        setupOpts.backend = "kitty";
      };
      outline.aerial-nvim.enable = true;
      diffview-nvim.enable = true;
      oil-nvim = {
        # TODO leader o/O - Oil, Oil.
        enable = true;
        setupOpts = {
          default_file_explorer = true;
          columns = [
            "icon"
            "permissions"
            "size"
            "mtime"
          ];
          delete_to_trash = true;
          skip_confirm_for_simple_edits = true;
          constrain_cursor = "editable";
          experimental_watch_for_changes = true;
          view_options = {
            show_hidden = true;
            natural_order = true;
            sort = [
              { type = "asc"; }
              { name = "asc"; }
            ];
          };
        };
      };
      surround = {
        enable = true;
        useVendoredKeybindings = false;
        # TODO check default keymaps
        setupOpts = {
          keymaps = {
            insert = "<C-g>s";
            insert_line = "<C-g>S";
            normal = "s";
            normal_cur = "ss";
            normal_line = "S";
            normal_cur_line = "SS";
            visual = "s";
            visual_line = "S";
            delete = "ds";
            change = "cs";
            change_line = "cS";
          };
        };
      };
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
      python.enable = true;
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
