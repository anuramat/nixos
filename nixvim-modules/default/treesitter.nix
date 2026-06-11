{
  config,
  ...
}:
{
  plugins = {
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
      };
    };

    treesitter-textobjects.enable = true;

    ts-comments.enable = true;

    treesitter-context = {
      enable = true;
      settings = {
        enable = true;
        max_lines = 1;
        min_window_height = 20;
        line_numbers = true;
        multiline_threshold = 1;
        trim_scope = "outer";
        mode = "cursor";
      };
    };

    treesj.enable = true;
  };

  keymaps =
    let
      inherit (config.lib) keymap luaf;
      # same as builtin v_an/v_in, which are shadowed by mini.ai
      select =
        kind: sign:
        luaf ''
          if vim.treesitter.get_parser(nil, nil, { error = false }) then
            vim.treesitter.select("${kind}", vim.v.count1)
          else
            vim.lsp.buf.selection_range(${sign}vim.v.count1)
          end
        '';
    in
    [
      (keymap "n" "<leader>j" (luaf ''require("treesj").toggle()'')
        "TreeSJ: Split/Join a Treesitter node"
      )
      (keymap [ "n" "x" ] "<c-space>" (select "parent" "") "Select parent node")
      (keymap "x" "<c-bs>" (select "child" "-") "Select child node")
    ];
}
