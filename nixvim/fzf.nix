{ lib, ... }:
{
  keymaps = [
    # FzfLua keymaps
    {
      mode = "n";
      key = "<leader>fo";
      action = "<cmd>FzfLua files<cr>";
      options.desc = "files [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fO";
      action = "<cmd>FzfLua oldfiles<cr>";
      options.desc = "oldfiles [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fa";
      action = "<cmd>FzfLua args<cr>";
      options.desc = "args [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fb";
      action = "<cmd>FzfLua buffers<cr>";
      options.desc = "buffers [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fm";
      action = "<cmd>FzfLua marks<cr>";
      options.desc = "marks [fzf]";
    }

    {
      mode = "n";
      key = "<leader>f/";
      action = "<cmd>FzfLua curbuf<cr>";
      options.desc = "curbuf [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>FzfLua live_grep<cr>";
      options.desc = "live_grep [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fG";
      action = "<cmd>FzfLua grep_last<cr>";
      options.desc = "grep_last [fzf]";
    }

    {
      mode = "n";
      key = "<leader>fd";
      action = "<cmd>FzfLua diagnostics_document<cr>";
      options.desc = "diagnostics_document [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fD";
      action = "<cmd>FzfLua diagnostics_workspace<cr>";
      options.desc = "diagnostics_workspace [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fs";
      action = "<cmd>FzfLua lsp_document_symbols<cr>";
      options.desc = "lsp_document_symbols [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fS";
      action = "<cmd>FzfLua lsp_workspace_symbols<cr>";
      options.desc = "lsp_workspace_symbols [fzf]";
    }
    {
      mode = "n";
      key = "<leader>ft";
      action = "<cmd>FzfLua treesitter<cr>";
      options.desc = "treesitter [fzf]";
    }

    {
      mode = "n";
      key = "<leader>fr";
      action = "<cmd>FzfLua resume<cr>";
      options.desc = "resume [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fh";
      action = "<cmd>FzfLua helptags<cr>";
      options.desc = "helptags [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fk";
      action = "<cmd>FzfLua keymaps<cr>";
      options.desc = "keymaps [fzf]";
    }
    {
      mode = "n";
      key = "<leader>fp";
      action = "<cmd>FzfLua builtin<cr>";
      options.desc = "builtin [fzf]";
    }

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
      files = {
        "1" = true; # merge with defaults
        "ctrl-q" = {
          fn.__raw = "require('fzf-lua').actions.file_sel_to_qf";
          prefix = "select-all";
        };
      };
    };
  };
}
