{
  config,
  ...
}:
{
  plugins = {
    treesitter = {
      enable = true;
      highlight.enable = true;
    };

    treesitter-textobjects.enable = true;

    ts-comments.enable = true;

    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 1;
        min_window_height = 20;
        multiline_threshold = 1;
      };
    };

    treesj.enable = true;
  };

  keymaps =
    let
      inherit (config.lib) keymap;
      # same as builtin v_an/v_in, which are shadowed by mini.ai
      select = kind: sign: {
        __raw = ''
          function()
            if vim.treesitter.get_parser(nil, nil, { error = false }) then
              vim.treesitter.select("${kind}", vim.v.count1)
            else
              vim.lsp.buf.selection_range(${sign}vim.v.count1)
            end
          end
        '';
      };
    in
    [
      (keymap "n" "<leader>j" {
        __raw = ''function() require("treesj").toggle() end'';
      } "TreeSJ: Split/Join a Treesitter node")
      (keymap [ "n" "x" ] "<c-space>" (select "parent" "") "Select parent node")
      (keymap "x" "<c-bs>" (select "child" "-") "Select child node")
    ];
}
