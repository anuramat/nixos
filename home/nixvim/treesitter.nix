{
  lib,
  pkgs,
  hax,
  ...
}:
{
  plugins = {
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        incremental_selection = {
          enable = true;
          keymaps = {
            node_decremental = "<bs>";
            node_incremental = "<c-space>";
          };
        };
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
      inherit (hax.vim) set lua;
    in
    [
      (set "<leader>j" (lua "function() require('treesj').toggle() end")
        "TreeSJ: Split/Join a Treesitter node"
      )
    ];
}
