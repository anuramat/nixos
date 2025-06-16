{ ... }:
{
  keymaps =
    let
      map = key: action: desc: {
        mode = "n";
        inherit key action;
        options = { inherit desc; };
      };
    in
    [
      (map "<leader>fo" "<cmd>FzfLua files<cr>" "files [fzf]")
      (map "<leader>fO" "<cmd>FzfLua oldfiles<cr>" "oldfiles [fzf]")
      (map "<leader>fa" "<cmd>FzfLua args<cr>" "args [fzf]")
      (map "<leader>fb" "<cmd>FzfLua buffers<cr>" "buffers [fzf]")
      (map "<leader>fm" "<cmd>FzfLua marks<cr>" "marks [fzf]")
      (map "<leader>f/" "<cmd>FzfLua curbuf<cr>" "curbuf [fzf]")
      (map "<leader>fg" "<cmd>FzfLua live_grep<cr>" "live_grep [fzf]")
      (map "<leader>fG" "<cmd>FzfLua grep_last<cr>" "grep_last [fzf]")
      (map "<leader>fd" "<cmd>FzfLua diagnostics_document<cr>" "diagnostics_document [fzf]")
      (map "<leader>fD" "<cmd>FzfLua diagnostics_workspace<cr>" "diagnostics_workspace [fzf]")
      (map "<leader>fs" "<cmd>FzfLua lsp_document_symbols<cr>" "lsp_document_symbols [fzf]")
      (map "<leader>fS" "<cmd>FzfLua lsp_workspace_symbols<cr>" "lsp_workspace_symbols [fzf]")
      (map "<leader>ft" "<cmd>FzfLua treesitter<cr>" "treesitter [fzf]")
      (map "<leader>fr" "<cmd>FzfLua resume<cr>" "resume [fzf]")
      (map "<leader>fh" "<cmd>FzfLua helptags<cr>" "helptags [fzf]")
      (map "<leader>fk" "<cmd>FzfLua keymaps<cr>" "keymaps [fzf]")
      (map "<leader>fp" "<cmd>FzfLua builtin<cr>" "builtin [fzf]")
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
