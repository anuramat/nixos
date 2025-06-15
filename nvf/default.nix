{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./git.nix
    ./fzf.nix
  ];
  package = inputs.neovim-nightly.packages.${pkgs.stdenv.system}.default;
  vim = {
    keymaps =
      let
        inherit (lib.nvim.binds) mkKeymap;
      in
      [
        (mkKeymap "n" "<leader>o" "<cmd>Oil<cr>" { })
        (mkKeymap "n" "<leader>O" "<cmd>Oil .<cr>" { })
      ];
    enableLuaLoader = true;
    options = lib.mkForce { }; # XXX kinda works, kills some of the attributes
    luaConfigPre = # lua
      ''
        vim.cmd('source ${./base.vim}')
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

    filetree.neo-tree.enable = true;
    formatter.conform-nvim.enable = true;
    lazy.enable = true;
    notes.todo-comments = {
      enable = true;
      setupOpts = {
        signs = false;
        mappings = {
          quickFix = lib.mkForce null;
        };
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
        filetypes = {
          "css" = { };
          "yaml" = { };
        };
      };
    };

    mini = {
      align.enable = true;
      bracketed.enable = true;
    };
    treesitter = {
      mappings.incrementalSelection = {
        decrementByNode = "<bs>";
        incrementByNode = "<c-space>";
        incrementByScope = lib.mkForce null;
        init = lib.mkForce null;
      };
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
            sort = {
              type = "asc";
              name = "asc";
            };
          };
        };
      };
      surround = {
        enable = true;
        useVendoredKeybindings = false;
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
      otter-nvim = {
        enable = true;
        mappings.toggle = lib.mkForce null; # mkforce doesn't work
      };
    };

    debugger.nvim-dap = {
      # XXX report broken key descriptions
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
